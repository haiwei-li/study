
# 1 cinder ServiceController

先来看看 cinder-list 的实现代码: 

```python
class ServiceController(wsgi.Controller):
    @wsgi.serializers(xml=ServicesIndexTemplate)
    def index(self, req):
        """Return a list of all running services.
        Filter by host & service name.
        """
        context = req.environ['cinder.context']
        authorize(context)
        detailed = self.ext_mgr.is_loaded('os-extended-services')
        now = timeutils.utcnow() # 获取当前时间
        services = db.service_get_all(context) # 获取service 列表
        ...
        svcs = []
        for svc in services:
            updated_at = svc['updated_at']
            delta = now - (svc['updated_at'] or svc['created_at']) # 获取 updated_at, 不存在的话, 获取 created_at. 并和当前时间计算时间差
            delta_sec = delta.total_seconds() # 转换成秒
            ...
            alive = abs(delta_sec) <= CONF.service_down_time # 检查是否小于配置的 server_down_time, 该配置项默认是60秒
            art = (alive and "up") or "down" # 如果差值小于60, 则service 状态为 up, 否则为 down
            active = 'enabled'
            if svc['disabled']: # 如何从数据库查询到的service disabled != 0,则表示service 状态是disabled
                active = 'disabled'
            ret_fields = {'binary': svc['binary'], 'host': svc['host'],
                          'zone': svc['availability_zone'],
                          'status': active, 'state': art,
                          'updated_at': updated_at}
            if detailed:
                ret_fields['disabled_reason'] = svc['disabled_reason']
            svcs.append(ret_fields)
        return {'services': svcs}
```

可见, service返回结果状态是否为up, 取决于now - updated_at 与CONF.service_down_time 谁大谁小. 

# 2 cinder updated_at更新机制

cinder-api, cinder-backup 等服务都是class Service(service.Service) 的一个实例, 它的start方法如下: 

```python
# cinder/service.py

class Service(service.Service):
    def start(self):
        version_string = version.version_string()
        LOG.info(_LI('Starting %(topic)s node (version %(version_string)s)'),
                 {'topic': self.topic, 'version_string': version_string})
        self.model_disconnected = False
        self.manager.init_host()
        ctxt = context.get_admin_context()
        try:
            service_ref = db.service_get_by_args(ctxt,
                                                 self.host,
                                                 self.binary)
            self.service_id = service_ref['id']
        except exception.NotFound:
            self._create_service_ref(ctxt)

        LOG.debug("Creating RPC server for service %s", self.topic)

        target = messaging.Target(topic=self.topic, server=self.host)
        endpoints = [self.manager]
        endpoints.extend(self.manager.additional_endpoints)
        serializer = objects_base.CinderObjectSerializer()
        self.rpcserver = rpc.get_server(target, endpoints, serializer)
        self.rpcserver.start()

        self.manager.init_host_with_rpc()

        if self.report_interval:
            # 启动一个循环来执行 report_state 方法, 运行间隔就是 report_interval, 其默认值是 10 秒,report_state会更新数据库
            pulse = loopingcall.FixedIntervalLoopingCall(
                self.report_state)
            pulse.start(interval=self.report_interval,
                        initial_delay=self.report_interval)
            self.timers.append(pulse)

        if self.periodic_interval:
            if self.periodic_fuzzy_delay:
                initial_delay = random.randint(0, self.periodic_fuzzy_delay)
            else:
                initial_delay = None

            periodic = loopingcall.FixedIntervalLoopingCall(
                self.periodic_tasks)
            periodic.start(interval=self.periodic_interval,
                           initial_delay=initial_delay)
            self.timers.append(periodic)
            
    def report_state(self):
        """Update the state of this service in the datastore."""
        ctxt = context.get_admin_context()
        zone = CONF.storage_availability_zone
        state_catalog = {}
        try:
            try:
                service_ref = db.service_get(ctxt, self.service_id)
            except exception.NotFound:
                LOG.debug('The service database object disappeared, '
                          'recreating it.')
                self._create_service_ref(ctxt)
                service_ref = db.service_get(ctxt, self.service_id)

            state_catalog['report_count'] = service_ref['report_count'] + 1 # report_count的值会加1
            if zone != service_ref['availability_zone']:
                state_catalog['availability_zone'] = zone

            db.service_update(ctxt,
                              self.service_id, state_catalog) # //更新该 service, 在更新的时候updated_at会自动根据当前时间更新

            # TODO(termie): make this pattern be more elegant.
            if getattr(self, 'model_disconnected', False):
                self.model_disconnected = False
                LOG.error(_LE('Recovered model server connection!'))

        except db_exc.DBConnectionError:
            if not getattr(self, 'model_disconnected', False):
                self.model_disconnected = True
                LOG.exception(_LE('model server went away'))

        # NOTE(jsbryant) Other DB errors can happen in HA configurations.
        # such errors shouldn't kill this thread, so we handle them here.
        except db_exc.DBError:
            if not getattr(self, 'model_disconnected', False):
                self.model_disconnected = True
                LOG.exception(_LE('DBError encountered: '))
```

report_state 方法会更新 db 中serive 的各个属性, 其中 updated_at 的值就是所在节点上执行一次该方法的时刻. 

再来看看循环的类FixedIntervalLoopingCall,上面的代码可以看到, FixedIntervalLoopingCall初始化的时候传入了self.report_state,  然后执行了start方法

```
# cinder/openstack/common/loopingcall.py
_ts = lambda: time.time()
class LoopingCallBase(object):
    def __init__(self, f=None, *args, **kw):
        self.args = args
        self.kw = kw
        self.f = f
        self._running = False
        self.done = None

    def stop(self):
        self._running = False

    def wait(self):
        return self.done.wait()


class FixedIntervalLoopingCall(LoopingCallBase):
    """A fixed interval looping call."""

    def start(self, interval, initial_delay=None):
        self._running = True
        done = event.Event()

        def _inner():
            if initial_delay:
                greenthread.sleep(initial_delay)

            try:
                while self._running:
                    start = _ts() # 记录更新数据库开始的时间
                    self.f(*self.args, **self.kw) # 根据传进来的相应函数, 执行相应的方法
                    end = _ts() # 记录更新数据库结束的时间
                    if not self._running:
                        break
                    delay = end - start - interval
                    if delay > 0:
                        LOG.warn(_LW('task %(func_name)r run outlasted '
                                     'interval by %(delay).2f sec'),
                                 {'func_name': self.f, 'delay': delay})
                    greenthread.sleep(-delay if delay < 0 else 0)
            except LoopingCallDone as e:
                self.stop()
                done.send(e.retvalue)
            except Exception:
                LOG.exception(_LE('in fixed duration looping call'))
                done.send_exception(*sys.exc_info())
                return
            else:
                done.send(True)

        self.done = done

        greenthread.spawn_n(_inner) # 调用函数_inner的绿色线程
        return self.done
```

# 3 问题定位

如果发现某个服务的状态为down,在启动日志没有出错的情况下, 可以按照下面的步骤进行定位: 

(1)看看是不是在 cinder.conf 中 report_interval 配置项的值是多少, 如果超过了 service_down_time 配置项默认的 60 秒, 那么该service 的状态肯定就是 'down' 了. 

(2)看 service 所在节点的时间, 它的时间和 controller 节点的时间误差必须在 [service_down_time - report_interval ] 之内, 也就是在使用默认配置情况下, 时间差必须在 50 秒之内. 

(3)看看 service 的 log 文件中, 确认 report_state  方法是不是都按时被调用了, 不方便看的话, 在代码中加个注释吧. 


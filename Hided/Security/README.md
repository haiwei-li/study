 computer security

密钥交换协议: 需要安全通信的双方使用该协议确定对称密钥, 是用来建立密钥的, 不是用来加密的. ECDHE>DHE> DH,RSA

- 信息加密: 对称加密

- 数据完整性: MD5

- 身份鉴定: 非对称加密(也可以用来信息加密, 不过太慢, 所以用来身份鉴定了), 数字证书就是公钥, 需要第三方机构发布, 浏览器之类的需要导入证书(公钥)

- 不可否认

#### 安全基础

如果说 socket,HTTP 建立了传输的通道, Hash 技术,对称/非对称加密,  数字签名等安全基础就是安全的守护者.

去看看最近大热的区块链, 会发现这些安全基础是区块链基本的技术支撑.

他们是如此重要, 到处都能看到他们的身影:

- HTTPS: 使用"非对称加密"来传输"对称加密的密钥", 使用 Hash, 数字签名来确保身份的合法性.

- Secure Shell :  使用 RSA 的方式登录服务器

Hash 的用途更为广泛:

- 用户密码的存储:  现在基本上没有网站存储明文密码了, 基本上都是把密码加 salt 生成 hash 值以后来保存.

- HashMap 等数据结构:  使用 Hash 来生成 key .

- Memcached : 分布式一致性 Hash 算法.

- 文件传输校验:  使用 Hash 算法生成消息摘要, 验证文件是否被篡改.

如果是做 Web 开发, 还必须得掌握 XSS/CSRF/SQL 注入等常见的 Web 攻击技术和和应对方案

推荐书籍:

《白帽子讲安全》

码农翻身文章:

《[一个故事讲完 HTTPS](http://mp.weixin.qq.com/s?__biz=MzAxOTc0NzExNg==&mid=2665513779&idx=1&sn=a1de58690ad4f95111e013254a026ca2&chksm=80d67b70b7a1f26697fa1626b3e9830dbdf4857d7a9528d22662f2e43af149265c4fd1b60024&scene=21#wechat_redirect)》

《[黑客三兄弟](http://mp.weixin.qq.com/s?__biz=MzAxOTc0NzExNg==&mid=2665514169&idx=1&sn=f6f8dffdb29c4075d094dd7203189e5b&chksm=80d67cfab7a1f5ecb7daf768a0364879c0d26483fd2e595d67bcf82822c5fbb9525323956d51&scene=21#wechat_redirect)》

《[黑客三兄弟续](http://mp.weixin.qq.com/s?__biz=MzAxOTc0NzExNg==&mid=2665514255&idx=1&sn=d187867dbd547351350b608a4810ab67&chksm=80d67d4cb7a1f45a227150ae0c4728ae2d23224de808308e735abf20b258decb30ac92ce9b34&scene=21#wechat_redirect)》
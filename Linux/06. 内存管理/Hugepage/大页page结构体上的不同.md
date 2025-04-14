
当 linux 内核分配普通页或者大页时, 都会对相应的 page 结构体做一定的初始化, 初始化的内容因分配的页是大页或者普通页会有一定的区别

```cpp
alloc_fresh_huge_page(); // 大页 size 小, 从页分配器分配
 ├─ struct page *page = alloc_buddy_huge_page(); // 本质是调用__alloc_pages, 直接分配了一个大页(2M/1G), 一共有很多 page 结构体, 返回首个 page 结构体
 ├─ prep_compound_gigantic_page(page, huge_page_order(h)) // hstate_is_gigantic 时候(目前是 1G size 的大页)
 // 所有大页都会调用其进行
 └─ prep_new_huge_page(h, page, page_to_nide(page)); // 所有大页都会调用其进行初始化
 │  ├─ INIT_LIST_HEAD(&page->lru);
; // page->lru 初始化
 │  ├─ set_compound_page_dtor(page, HUGETLB_PAGE_DTOR); // page[1].compound_dtor = HUGETLB_PAGE_DTOR
 │  ├─ hugetlb_set_page_subpool(page, NULL); // page[1].private=NULL
 │  ├─ set_hugetlb_cgroup(page, NULL); // 设置 page[2].private 为 NULL
 │  ├─ set_hugetlb_cgroup_rsvd(page, NULL); // 设置 page[3].private 为 NULL
 │  ├─ h->nr_huge_pages++; //
 │  └─ h->nr_huge_pages_node[nid]++; //
```

核心入口函数是 `alloc_fresh_huge_page`

```cpp
/*
 * Common helper to allocate a fresh hugetlb page. All specific allocators
 * should use this function to get new hugetlb pages
 */
static struct page *alloc_fresh_huge_page(struct hstate *h,
		gfp_t gfp_mask, int nid, nodemask_t *nmask)
{
	struct page *page;

	if (hstate_is_gigantic(h))
		page = alloc_gigantic_page(h, gfp_mask, nid, nmask);
	else
		page = alloc_buddy_huge_page(h, gfp_mask,
				nid, nmask);
	if (!page)
		return NULL;

	if (hstate_is_gigantic(h))
		prep_compound_gigantic_page(page, huge_page_order(h));
	prep_new_huge_page(h, page, page_to_nid(page));

	return page;
}
```

可以看到, 大页的话, 在普通页分配函数 `alloc_buddy_huge_page`(本质是调用 `__alloc_pages_nodemask` 函数)初始化后的基础上, 又进行了 `prep_compound_gigantic_page` (如果是 gigantic 页)以及 `prep_new_huge_page` 两个函数的初始化.

**普通页**的**初始化**位于函数 `prep_new_page` 中, 需要注意 `__GFP_COMP` 字段, 这里不做过多分析.

下面来看 `prep_new_huge_page` 函数, **所有大页**都会调用这个函数进行**初始化**.

```cpp
static void prep_new_huge_page(struct hstate *h, struct page *page, int nid)
{
	INIT_LIST_HEAD(&page->lru);
	set_compound_page_dtor(page, HUGETLB_PAGE_DTOR);
	spin_lock(&hugetlb_lock);
	set_hugetlb_cgroup(page, NULL);
	h->nr_huge_pages++;
	h->nr_huge_pages_node[nid]++;
	ClearPageHugeFreed(page);
	spin_unlock(&hugetlb_lock);
}
```

第一行, 初始化 lru 成员, **与普通页相同**.

第二行, 调用 `set_compound_page_dtor` 设置 `page[1].compound_dtor = HUGETLB_PAGE_DTOR;` 注意, 是`page[1]`的 `compound_dtor` 成员

第四行, 设置 `page[2].private` 为 NULL

第五行, 设置 `(head + 4).private` 为 0

下面再看 `prep_compound_gigantic_page` 函数, x86 上只有 1G 大页会调用这个函数进行初始化.

```cpp
static void prep_compound_gigantic_page(struct page *page, unsigned int order)
{
	int i;
	int nr_pages = 1 << order;
	struct page *p = page + 1;

	/* we rely on prep_new_huge_page to set the destructor */
	set_compound_order(page, order);
	__ClearPageReserved(page);
	__SetPageHead(page);
	for (i = 1; i < nr_pages; i++, p = mem_map_next(p, page, i)) {
		/*
		 * For gigantic hugepages allocated through bootmem at
		 * boot, it's safer to be consistent with the not-gigantic
		 * hugepages and clear the PG_reserved bit from all tail pages
		 * too.  Otherwse drivers using get_user_pages() to access tail
		 * pages may get the reference counting wrong if they see
		 * PG_reserved set on a tail page (despite the head page not
		 * having PG_reserved set).  Enforcing this consistency between
		 * head and tail pages allows drivers to optimize away a check
		 * on the head page when they need know if put_page() is needed
		 * after get_user_pages().
		 */
		__ClearPageReserved(p);
		set_page_count(p, 0);
		set_compound_head(p, page);
	}
	atomic_set(compound_mapcount_ptr(page), -1);
}
```

`set_compound_order` 函数, 把 `page[1].compound_order` 设置为相应的 order

然后, 从第 `[1]` 个**page**开始, 依次标记为**尾页**, 然后将 `_refcount` 设置为 0, 然后, 把 `page[1].compound_mapcount` 设置为 `-1`.

可以看到, **大页与普通页相比**, 首个 page 大部分是一样的, 但因为**大页**有**多个 page 结构体可以使用**, 从而会在**第二个 page 开始**的结构体**相关成员标记某些信息**, 这是与普通页的最大区别, 这也可以从 **page 结构体**的**第一个 union** 中看的出来.

细节就不写了, 用到的时候才能记住.

# reference

https://blog.csdn.net/kaka__55/article/details/122004400
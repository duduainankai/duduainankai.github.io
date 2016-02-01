---
layout: page
title: "标签"
date: 2013-07-28 23:11
comments: false
sharing: false
footer: false
---
<section>
	<ul id="categories">
	{% for item in site.categories %}
	    <li><a href="/blog/categories/{{ item[0] }}/">{{ item[0] | capitalize }}</a> [ {{ item[1].size }} ]</li>
	{% endfor %}
	</ul>
</section>
<!--
<section>
  <ul id="categories">
    {% category_list %}
  </ul>
</section>
-->
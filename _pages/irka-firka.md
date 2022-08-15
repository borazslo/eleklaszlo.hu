---
layout: page
title: "Írka-firka"
permalink:  /7007/ 
published: true
tags:  [  ] 
---
Írni jó. Írni szoktam. Itt vannak a témák:

<!--<h2>Tagcloud</h2>-->
<section id="categories" markdown="0">
<br/>{% include tagcloud.html %}
<br/><hr><br/>
</section>


{% for tag in site.tags %}
  {% assign t = tag | first %}
  {% assign posts = tag | last %}

<h3>{{ t | downcase }}</h3>
<ul>
{% for post in posts %}
  {% if post.tags contains t %}
  <li>
    <a href="{{ post.url }}">{{ post.title }}</a>
    <span class="date">{{ post.date | datehun  }}</span>
  </li>
  {% endif %}
{% endfor %}
</ul>
{% endfor %}
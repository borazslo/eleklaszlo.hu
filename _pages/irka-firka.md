---
layout: page
title: "Írka-firka"
permalink:  /7007/ 
published: true
tags:  [  ] 
---
Írni jó. Írni szoktam. Itt vannak a témák:

<section id="categories" markdown="0">
{% assign featured_tags = "túrák,könyv,emlék,hivatás,fülöp-szigetek" | split: "," %}
<div class="tagcloud">
{% capture temptags %}
  {% for tag in site.tags %}
    {{ tag[1].size | plus: 1000 }}#{{ tag[0] }}#{{ tag[1].size }}&&
  {% endfor %}
{% endcapture %}
{% assign sortedtemptags = temptags | split: "&&" | sort | reverse %}
{% for temptag in sortedtemptags %}
  {% assign tagitems = temptag | split: '#' %}
  {% assign tagname = tagitems[1] %}
  {% assign tagsize = tagitems[2] | plus: 0 %}
  {% assign tagnamedown = tagname | downcase %}
  {% if tagsize > 0 %}<a href="#tag-{{ tagname | slugify }}" title="{{ tagsize }} tartalom" class="tag-chip{% if featured_tags contains tagnamedown %} tag-chip-featured{% endif %}">{{ tagname }} <span class="tag-count">{{ tagsize }}</span></a>{% endif %}
{% endfor %}
</div>
<br/><hr><br/>
<p class="archive-link"><a href="{{ "/archivum/" | relative_url }}" class="tag-chip">Évenkénti rendezésben: teljes archívum →</a></p>
<br/><hr><br/>
</section>

{% for tagpair in site.tags %}
  {% assign tagname = tagpair | first %}
  {% assign tagposts = tagpair | last | sort: 'date' | reverse %}

<h2 id="tag-{{ tagname | slugify }}">{{ tagname }}</h2>
<ul class="archive-list">
  {% for post in tagposts %}
  <li>
    <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
    {% if post.tags.size > 0 %}
    <span class="archive-tags">
      {% for tag in post.tags %}<a href="/cimke/{{ tag | slugify }}">#{{ tag }}</a> {% endfor %}
    </span>
    {% endif %}
    <span class="archive-date">{{ post.date | datehun }}</span>
  </li>
  {% endfor %}
</ul>
{% endfor %}

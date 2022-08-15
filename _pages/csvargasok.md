---
layout: page
title: "Csavargások"
permalink:  /7008/ 
published: true
tags:  [  ] 
---
Csavarogtam erre-arra és még fogok is. 

<ul>
{% for post in site.tags["TÚRÁK"] %}
  <li>
    <a href="{{ post.url }}">{{ post.title }}</a> ({{ post.date | date: "%Y" }})
  </li>
{% endfor %}
</ul>

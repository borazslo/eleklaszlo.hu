# eleklaszlo.hu
Teljes weblap - jekyll-travis

 exec jekyll-server --host 0.0.0.0
 
 docker run -rm -v C:\DevServer\eleklaszlo.hu:/srv/jekyll -p 4000:4000 -it jekyll/jekyll jekyll server --force_polling --livereload
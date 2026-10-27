---
layout: post
title: "Így vagyok"
permalink:  /6058/
date: 2014-09-24 04:03:07
tags:  [ életjel, USA ]
image:  /files/images/2014-09-24-igy-vagyok/DSC_3291.jpg
---
*Nagyon boldog vagyok: testem, lelkem, elmém a helyén van, és megfelelő mértékben meg is dolgoztatik. Nagyon kivagyok: testem, lelkem, elmém idegen helyen van, és erején felül meg is dolgoztatik.*

<!--break-->

Láttam az Óceánt és vitorlázni is voltam (kétszer). Hetente focizom és kerékpárral járok mindenhova (legyőzőm az MBTA-t). Éneklek egy kis kórusban és talán majd zenélni is fogok velük (kapok basszus furulyát). Segítenek az angolomat fejleszteni, járok pszichológushoz, és még imádkozom is.
{: .igyvagyok-verzio .igyvagyok-boldog}

Az egyetemet élvezem. Az órákra készülve félnapokat ülök a könyvtárba. Az olvasottakat a tanárral közösen jól felboncoljuk, majd tovább fűzve a gondolatokat rövid beadandókat írok angolul. És még érdekel is.
{: .igyvagyok-verzio .igyvagyok-boldog}

Képtelen vagyok ennyit olvasni. Még ha van is elég időm, a fejem akkor sem bírja. A fenekem sem. Vizsgaidőszakokban nem ültem ennyit könyv felett. Írni sem írtam ennyit. Le kell adnom hétfőig újabb három dolgozatot. Beszélnem legalább nem kell sokat. De az a kevés csak dühít: egy összetettebb gondolatomat nem tudom igazán lefordítani, még a történet mesélés sem megy.
{: .igyvagyok-verzio .igyvagyok-kivagyok}

Elégedettek az angol tudásommal, elégedettek még velem is. Csak én nem vagyok elégedett magammal: türelmesebbnek kéne lennem. Magamhoz.
{: .igyvagyok-verzio .igyvagyok-kivagyok}

*Kattints, mert van, hogy nem is így vagyok.*
{: #igyvagyok-csere style="cursor:pointer;"}

<script>
(function () {
  var boldog = document.getElementsByClassName('igyvagyok-boldog');
  var kivagyok = document.getElementsByClassName('igyvagyok-kivagyok');
  var mutatBoldog = Math.random() < 0.5;

  function frissit() {
    for (var i = 0; i < boldog.length; i++) boldog[i].style.display = mutatBoldog ? '' : 'none';
    for (var i = 0; i < kivagyok.length; i++) kivagyok[i].style.display = mutatBoldog ? 'none' : '';
  }

  frissit();

  document.getElementById('igyvagyok-csere').addEventListener('click', function () {
    mutatBoldog = !mutatBoldog;
    frissit();
  });
})();
</script>

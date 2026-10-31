# 2009 Világi Tor Túra — flickr-képek rendbetétele

> Állapot: folyamatban · 2026-10-31

## Cél

A "2009 Világi Tor Túra" kategória 22 posztjában a szövegbe ágyazott, apró
flickr thumbnail HTML-ek (`<p><a href="flickr.com/..."><img src="staticflickr...">...`)
helyett: nagy méretű kép letöltve a `files/images/<slug>/imgN.jpg` mappába,
rendes markdown képszintaxis (`![alt](path)`) a szövegben, saját sorban (nem
a bekezdésbe betűzve). Minden poszt első beágyazott képe kerüljön az `image:`
front matter mezőbe is (ahol ez a mező még nincs kitöltve), és akkor az
inline felsorolásból/szövegből kivehető, hogy ne legyen duplikált.

## Döntések

- Flickr-ről az eredeti ("o") méretű képet töltjük le a fotó oldaláról
  kinyert `sizes.o.url` JSON-mezőből (nem a 500px-es beágyazott thumbnailt).
  Ha egy fotóhoz nincs "o" méret, a legnagyobb elérhető ("l"/"k"/"h") a
  második választás.
- Letöltés: egy Python szkript a scratchpadben, ami photo ID → post slug
  párokból dolgozik, és egyenesen a megfelelő `files/images/<slug>/` mappába
  menti imgN.jpg néven (sorrend szerint, 1-től). Nem bash/curl egysoros
  láncolva, hogy ne kelljen soronta engedélyt kérni.
- A markdown fájlok front matter és szöveg szerkesztése posztonként Read+Edit
  eszközzel megy, nem bash/sed scripttel (korábbi felhasználói visszajelzés:
  `feedback_edit_over_scripts`).
- Két eset van, ahol ugyanaz a flickr fotó kétszer szerepel: a "Terezin" kép
  kétszer egymás után az Elba menti posztban (valószínűleg elgépelés — a
  második előfordulást kivesszük, nem duplikáljuk a képet), és a "DSC_2357"
  kép, ami két külön poszt végén/elején szerepel (ugyanaz a jelenet, mindkét
  posztban marad, csak egyszer töltjük le, mindkét posztban rá hivatkozunk).
- `2009-08-02-vilagi-tor-tura.markdown`, `2009-08-12-beka.markdown`: nincs
  bennük flickr-kép, nincs velük dolgunk.
- `2009-08-23-vilagi-tor-tura-2009.markdown`: már van `image:` mezője
  (`flickr_3794629027.jpg`, régebben letöltve), ezt nem bántjuk.

## Checklist

- [ ] Flickr fotó-oldalak lekérése és az eredeti kép URL-jének kinyerése
      mind az ~27 egyedi fotó ID-hoz → kész, ha: a scratchpadben van egy
      JSON/lista photo_id → eredeti URL párosítással, hiba nélkül.
- [ ] Képek letöltése a megfelelő `files/images/<slug>/imgN.jpg` helyekre →
      kész, ha: minden várt fájl létezik és mérete nem a kis thumbnail
      méret (nem ~30-80KB, hanem nagyobb felbontású fájl).
- [ ] `2009-08-04-indulas-elott.markdown` átírása (3 kép, image: mező) →
      kész, ha: a build-ben megjelenik a cover + 2 inline kép.
- [ ] `2009-08-05-az-elso-kilometerek.markdown` átírása (3 kép)
- [ ] `2009-08-05-vetett-agy.markdown` átírása (1 kép)
- [ ] `2009-08-06-atjutottam-a-csehorszagba.markdown` átírása (3 kép)
- [ ] `2009-08-07-a-harmadik-nap-szenvedese.markdown` átírása (2 kép)
- [ ] `2009-08-08-detoxikalas.markdown` átírása (1 kép)
- [ ] `2009-08-08-pragaig-hosszu-volt-az.markdown` átírása (3 kép)
- [ ] `2009-08-09-praga.markdown` átírása (3 kép)
- [ ] `2009-08-10-adjon-isten-csendes-esot.markdown` átírása (1 kép)
- [ ] `2009-08-10-az-elba-menten.markdown` átírása (6 egyedi kép, 1 dupla
      előfordulás kivéve)
- [ ] `2009-08-11-dresda-es-azon-tul.markdown` átírása (3 kép, elsőhöz
      meglévő letöltött fájl újrahasznosítva)
- [ ] `2009-08-12-jaj-nekem.markdown` átírása (3 kép)
- [ ] `2009-08-12-magany.markdown` átírása (1 kép)
- [ ] `2009-08-13-tengerecki-pal.markdown` átírása (2 kép)
- [ ] `2009-08-14-behajoztam.markdown` átírása (6 kép)
- [ ] `2009-08-14-magyarok.markdown` átírása (1 kép)
- [ ] `2009-08-15-ime-eljott.markdown` átírása (4 kép)
- [ ] `2009-08-16-vasarnap.markdown` átírása (1 kép)
- [ ] `2009-09-09-itt-a-mese-vege.markdown` átírása (1 kép)
- [ ] Docker/Jekyll dev szerveren (localhost:4000) szemrevételezés néhány
      érintett posztnál → kész, ha: a képek betöltődnek, nincs törött link.

## Nyitott kérdések

- Nincs.

## Teendők a felhasználónál

- Nincs — minden adat (fotó ID-k, posztok) a meglévő fájlokból kinyerhető.

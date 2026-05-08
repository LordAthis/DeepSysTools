# DeepSysTools
**Eldugott és törölt Windows rendszereszközök és beállítások könnyen elérhetővé tétele.**
**Verzió:** 1.x

Make hidden and deleted system tools and settings available - Eldugott és törölt Rendszereszközök és beállítások elérhetővé tétele.

---

## Mi ez?

A DeepSysTools egy **PowerShell alapú launcher**, amely visszahozza azokat a klasszikus Windows eszközöket és beállításokat, amelyeket a modern Windows 10/11 verziókban egyre jobban elrejtettek, átirányítottak vagy teljesen eltávolítottak (különösen Home kiadásokban).

### Főbb funkciók

- Kategóriarendszerű menü
- Több mint 30+ klasszikus rendszereszköz (Control Panel, MSC snap-ek, stb.)
- OS-verzió felismerés (Windows 10 / 11 specifikus kezelések)
- Automatikus .ps1 szkriptek futtatása (pl. Group Policy Home-on történő engedélyezése)
- God Mode, klasszikus Vezérlőpult, Hálózati kapcsolatok, stb.
- JSON alapú konfiguráció → könnyen bővíthető

---

## Használat

1. Töltsd le a repository-t (vagy klónozd)
2. **Jobb klikk** a `Launcher.ps1` fájlra → **"Futtatás PowerShell-lel"** (vagy futtasd adminisztrátorként)
3. Válassz kategóriát, majd eszközt

> **Megjegyzés:** Az első indításkor adminisztrátori jogokat kér a launcher.

## Mappa struktúra

- **DeepSysTools/**
  - **Launcher.ps1** ← Fő indító
  - **SysList.json** ← Eszköz adatbázis
  - **Scripts/**
    - GpeditMSC/
    - LusrmgrMSC/
    - WordPad/
    - .../
  - **Sys/** ← (rendszerfájlok, ha szükséges)
  - **LOG/** ← Futási naplók


## Támogatott eszközök (példák)

- **Klasszikus Vezérlőpult**
- **God Mode**
- **Csoportházirend (gpedit.msc)** – Home-on is
- **Helyi felhasználók kezelése (lusrmgr.msc)**
- **Hálózati kapcsolatok (ncpa.cpl)**
- **Lemezkarbantartó**, **Teljesítményfigyelő**, **Esemény-napló**, stb.
- És még sok más...

---

## Fejlesztés / Bővítés

Új eszköz hozzáadása:
1. Szerkeszd a `SysList.json` fájlt
2. Szükség esetén hozz létre mappát a `Scripts\<ID>\` alatt
3. Tedd bele a `Default.ps1` és/vagy `W11.ps1` szkripteket

---


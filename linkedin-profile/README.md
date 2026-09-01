# LinkedIn profile kit — Xclusive Senior Care

Everything needed to turn
`linkedin.com/in/xclusive-senior-day-center-undefined-293040433`
into a professional, bilingual presence: the images, the words, and the order to do
it in.

| File | What it is |
|---|---|
| **README.md** (this file) | Do the steps in order |
| **PROFILE-COPY.md** | Every text box, ready to copy and paste |
| **PHOTO-GUIDE.md** | Which of your own photos to use, and which not to |
| **images/** | The finished pictures — upload these as they are |
| **src/**, **build.py** | How the images were made, in case you want to change them |

---

## The images

| File | Size | Where it goes |
|---|---|---|
| `images/profile-picture-400x400.png` | 400 × 400 | Profile picture, and the Company Page logo |
| `images/banner-profile-1584x396.png` | 1584 × 396 | The wide cover behind your name |
| `images/banner-company-1128x191.png` | 1128 × 191 | The Company Page cover — **a different size, don't swap them** |

All three are built from facts already on your license and in your email signature:
two locations in Hialeah and Hialeah Gardens, AHCA #9102, RN on site, one caregiver
per four seniors, meals and transportation included, $0 with Medicaid Long-Term
Care, (305) 820-0805, Monday–Friday 9–5.

The profile picture is designed for LinkedIn's circular crop — everything sits
inside the circle, and it still reads at the small size used in the feed.

---

## Before anything else: two account fixes

You are signed into LinkedIn with **Sign in with Google** on
`XclusiveSenior@gmail.com` (Google recorded it on August 31).

**1. Set a real LinkedIn password.**
Right now, whoever controls that Google account controls this LinkedIn account, and
there is no second way in. Given what is in `OWNERSHIP-TRANSFER-CHECKLIST.md` in
this repo, that is worth closing today.
→ **Settings & Privacy → Sign in & security → Change password** → set one.
Then **Two-step verification** → turn it on.

**2. Add your business email as a backup.**
→ **Settings & Privacy → Sign in & security → Email addresses → Add email address**
→ `info@xclusiveseniorcare.com`. Now you can still get in if the Gmail is ever lost.

> ⚠️ **About syncing your Gmail contacts.** LinkedIn will offer to import everyone in
> your Gmail and invite them. **Don't accept the bulk invite.** That address book has
> participants and their family members in it, and a mass invite would tell everyone
> who received it that those people are connected to an adult day care — which is
> exactly the kind of disclosure you don't want. If you use the importer at all,
> tick names one at a time: referral sources, case managers, plan reps, vendors.

---

## Fixing the profile, in order

### 1. Fix the name — this is the "undefined" problem
The word *undefined* is in your profile URL because the account was created without
a last name. It shows up in search results and it looks broken.

**Profile → the pencil next to your name (Edit intro)**
- First name: `Xclusive Senior`
- Last name: `Day Care Center`
- Save.

### 2. Add the profile picture
Click the photo circle → **Add photo** → upload
`images/profile-picture-400x400.png` → it will offer a cropper; leave it centred →
**Save**.

### 3. Add the cover image
Click the wide grey area at the top → the camera icon → **Change photo** → upload
`images/banner-profile-1584x396.png` → **Apply**.

### 4. Headline and About
Copy them from **PROFILE-COPY.md**, sections 2 and 3.
Edit intro → **Headline**. Then **Add profile section → About**.

### 5. Fix the profile URL
Get *undefined* out of your web address.
**Profile → "Edit public profile & URL"** (top right of the page) → the pencil next
to your URL → change it to:

```
linkedin.com/in/xclusive-senior-care
```

If that exact one is taken, try `xclusive-senior-care-fl` or
`xclusive-senior-daycare`. Then update the link anywhere you have already shared it.

### 6. Contact info
Edit intro → **Contact info**:
- Website: `https://xclusiveseniorcare.com` (label it *Company Website*)
- Phone: `(305) 820-0805`
- Email: `info@xclusiveseniorcare.com`
- Address: `12975 W. Okeechobee Rd., Units 2-4, Hialeah Gardens, FL 33018`

The personal profile holds one address. **Both** locations go on the Company Page in
the next step — that is what makes you findable in searches for either city.

### 7. Create the Company Page — the piece that's actually missing
A profile under `/in/` is LinkedIn's format for a *person*. A business belongs on a
**Company Page**, and running a business on a personal profile is against LinkedIn's
User Agreement — accounts do get restricted for it. A Page is free, it can be found
in LinkedIn search by people looking for adult day care, employees can list you as
their employer, and you can post as the business.

Do both: keep the personal profile fixed up as the owner's/administrator's account,
and put the business on a Page.

**From the top nav: For Business (grid icon) → Create a Company Page → Company.**

Fill it in from **PROFILE-COPY.md section 6**. Upload
`images/profile-picture-400x400.png` as the logo and
`images/banner-company-1128x191.png` as the cover.

### 8. Add the Spanish profile
This is what makes "100% bilingual" true on the page itself, instead of just claimed.

**Profile → Add profile section → Add profile in another language → Spanish.**
Paste the Spanish headline and About from **PROFILE-COPY.md section 4**. Spanish
speakers will now see the Spanish version automatically.

### 9. Experience, Skills, Featured
- **Experience** — PROFILE-COPY.md section 5. Pick the Company Page from the
  dropdown so the profile and the Page link to each other.
- **Skills** — PROFILE-COPY.md section 7.
- **Featured** — Add profile section → Featured → add your website link and 3–4
  photos. See **PHOTO-GUIDE.md** for which photos, and read the HIPAA note there
  before you post any photo with a participant in it.

### 10. Post something
An empty profile looks abandoned. Post the launch text from **PROFILE-COPY.md
section 8** (English) or **section 9** (Spanish) with two or three photos.

---

## Changing the images later

The images are generated from HTML, so a phone number or a tagline is a one-line
edit rather than a redesign.

```bash
cd linkedin-profile/src
# edit brand.css for colours, or the .html files for wording
python3 build.py            # rewrites everything in ../images
```

`src/brand.css` holds the palette — deep navy `#0E3A4F`, gold `#D6A03D`, cream
`#FAF6EE`. If Xclusive has official brand colours, put them there and re-run the
build; all three images change together.

Requires Python with Pillow (`pip install pillow`) and Chromium. `build.py` finds
Chromium automatically, or you can add the path to `CHROME_CANDIDATES` at the top.

---

## The one thing still missing

**The street address of the Hialeah location.** Everything else is confirmed and
written in. Both banners, the About sections in both languages, the headline, the
Experience entry and the Company Page all say *two locations* — but only the Hialeah
Gardens street address is filled in, because the Hialeah one isn't recorded anywhere
I could reach.

Search `[HIALEAH ADDRESS]` in **PROFILE-COPY.md** — it appears in four places
(English About, Spanish About, the facts table, and the Page's Locations list).
Type the address in once you have it, or tell me and I'll fill it in for you.

Separately, before posting any photo with a participant in it, read **PHOTO-GUIDE.md
section 1** — that one is a HIPAA question, not a copy question.

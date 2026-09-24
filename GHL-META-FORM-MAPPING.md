# Senior Ventures — Meta Lead Form → GHL Mapping

Goal: every lead from the Senior Ventures (SV) Meta lead form lands in GHL with
name, phone, email **and all 7 qualifying answers** on the contact record.

Everything below is done in the GHL web app (phone browser works).

---

## Quick fix — map Q7 (contact_confirmation) in GHL

In GHL go to **Settings → Integrations → Facebook** → select the **SV page** →
select the **lead form** → **Field Mapping**.

Add a new row:

| Facebook field         | GHL field            |
|------------------------|----------------------|
| `contact_confirmation` | Contact Confirmation |

**Save.** That maps Q7.

> If "Contact Confirmation" isn't in the GHL field list, create it first under
> **Settings → Custom Fields** (Single Line), then add the row.

---

## Step 0 — Make sure Q7 is on the Meta form

If the live SV form has only 6 questions, add Q7 (`contact_confirmation`)
first. **Meta won't let you edit a published Instant Form**, so:

1. **Meta Business Suite → All tools → Instant Forms**. Find the SV form,
   open the **⋯** menu and choose **Duplicate**.
2. In the copy, go to **Questions → Add question → Multiple choice**:
   - Question: `I confirm I am a serious buyer and want to be contacted about this opportunity`
   - Answers: `Yes, contact me` / `No`
   - Under **Field name**, set it to `contact_confirmation` if that option is shown
3. Check that the other 6 questions, the privacy policy and the thank-you screen
   carried over. Then **Publish**.
4. **Ads Manager → the SV ad → Edit → Instant form**: switch to the new form and
   click **Publish**.
5. In GHL, map the **new** form (Step 2). GHL treats it as a different form, so
   the old mapping doesn't carry over.

---

## Step 1 — Create the 7 custom fields

**Settings → Custom Fields → + Add Field.** Put them all in one folder called
**Senior Ventures** so they're easy to find on the contact record.

Use **Single Line** as the type. Meta sends the answer as plain text; a Single
Line field accepts it exactly as sent. (A Dropdown only works if every option is
typed *character-for-character* identical to the Meta option, including
commas. One typo and that answer arrives blank.)

| # | GHL field name        | Type        | Meta question key       |
|---|-----------------------|-------------|-------------------------|
| 1 | Liquid Capital        | Single Line | `liquid_capital`        |
| 2 | Prior Acquisition     | Single Line | `prior_acquisition`     |
| 3 | Healthcare Experience | Single Line | `healthcare_experience` |
| 4 | NDA Readiness         | Single Line | `nda_readiness`         |
| 5 | Price Awareness       | Single Line | `price_awareness`       |
| 6 | Purchase Type         | Single Line | `purchase_type`         |
| 7 | Contact Confirmation  | Single Line | `contact_confirmation`  |

If you do want Dropdowns (for cleaner filtering later), copy the options below
exactly:

**Liquid Capital:** "Do you have $2.5M or more in liquid capital or financing?"
- Yes, I have the capital ready
- Working on financing
- Through investors or partners
- No

**Prior Acquisition:** "Have you acquired a business before?"
- Yes, multiple businesses
- Yes, one business
- No, this would be my first
- Through a group or fund

**Healthcare Experience:** "Do you have experience in healthcare or senior care?"
- Currently in the industry
- Related industry experience
- No, but very interested
- Through partners or advisors

**NDA Readiness:** "Are you ready to sign an NDA to receive financial details?"
- Yes, ready to sign now
- Need more information first
- Will have attorney review
- Not at this time

**Price Awareness:** "Are you comfortable with the $2.5M asking price?"
- Yes
- Need to evaluate further
- No

**Purchase Type:** "How would you structure the purchase?"
- Individual buyer
- Partnership or group
- Corporate acquisition
- Investment fund

**Contact Confirmation:** "I confirm I am a serious buyer and want to be
contacted about this opportunity"
- Yes, contact me
- No

---

## Step 2 — Connect the form

1. **Settings → Integrations → Facebook** (connect with the account that admins
   the SV page, if not already connected).
2. Open **Facebook Form Field Mapping**.
3. Pick the **SV page**, then the **SV lead form**.

---

## Step 3 — Map the fields

Standard fields (usually auto-mapped — confirm they are):

| Meta field   | GHL field  |
|--------------|------------|
| Full name    | Full Name  |
| Phone number | Phone      |
| Email        | Email      |

Custom questions:

| Meta question           | → GHL custom field    |
|-------------------------|-----------------------|
| `liquid_capital`        | Liquid Capital        |
| `prior_acquisition`     | Prior Acquisition     |
| `healthcare_experience` | Healthcare Experience |
| `nda_readiness`         | NDA Readiness         |
| `price_awareness`       | Price Awareness       |
| `purchase_type`         | Purchase Type         |
| `contact_confirmation`  | Contact Confirmation  |

Click **Save**.

---

## Step 4 — Send a test lead

1. Open Meta's **Lead Ads Testing Tool**:
   `https://developers.facebook.com/tools/lead-ads-testing`
2. Select the SV page and the SV form. **Delete any existing test lead** (Meta
   allows only one per form), then **Create lead**.
3. In GHL → **Contacts**, the test contact should appear within ~1 minute.
4. Open it and check that all 7 fields in the **Senior Ventures** folder are
   filled in.

If one field is blank, go back to Step 3: that question wasn't mapped, or it's a
Dropdown whose options don't match exactly.

---

## Optional — flag hot buyers automatically

After mapping, a workflow can tag serious buyers right away:

- **Trigger:** Facebook Lead Form Submitted (SV form)
- **If/Else:** Liquid Capital = `Yes, I have the capital ready`
  **AND** NDA Readiness = `Yes, ready to sign now`
  **AND** Contact Confirmation = `Yes, contact me`
- **Yes branch:** add tag `sv-hot-buyer` → send internal notification / assign
  owner
- **No branch:** add tag `sv-nurture`

Treat anyone who answers Contact Confirmation = **No** as do-not-call for this
opportunity.

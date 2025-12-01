# Fixing Leaderboard on GitHub Pages (CORS Issue)

## Problem

The leaderboard works locally but not on GitHub Pages. This is because of CORS (Cross-Origin Resource Sharing) restrictions.

When your game runs on GitHub Pages (e.g., `https://username.github.io/ai-microgames/`), the browser blocks requests to Supabase unless CORS is properly configured.

## Solution: Enable CORS in Supabase

### Step 1: Go to Supabase Dashboard

1. Visit https://supabase.com/dashboard
2. Select your project: `yyafrfrgayzgclwudkhp`

### Step 2: Configure CORS Settings

**Option A: Using Supabase Dashboard (Recommended)**

1. Go to **Settings** → **API**
2. Scroll down to **CORS Settings** or **Additional CORS domains**
3. Add your GitHub Pages URL:
   ```
   https://tombarr.github.io
   ```
4. If you want to allow all domains (for testing), you can add:
   ```
   *
   ```
   ⚠️ **Warning**: Using `*` allows any website to access your leaderboard. Only use this for testing!

**Option B: Using Edge Functions (Advanced)**

If the dashboard doesn't have CORS settings, you may need to:
1. Go to **SQL Editor**
2. Create an edge function to handle CORS headers
3. Or contact Supabase support to enable CORS for your domain

### Step 3: Verify the Fix

1. Deploy your game to GitHub Pages
2. Open the browser console (F12)
3. Check for CORS errors
4. The leaderboard should now load

## Common CORS Error Messages

If you see these in the browser console, it's a CORS issue:

```
Access to fetch at 'https://yyafrfrgayzgclwudkhp.supabase.co/rest/v1/leaderboard'
from origin 'https://tombarr.github.io' has been blocked by CORS policy
```

```
Response code: 0
(Response code 0 often indicates CORS issues on web builds)
```

## Alternative: Use Supabase Edge Functions

If CORS configuration isn't available, you can create a Supabase Edge Function that acts as a proxy:

1. Go to **Edge Functions** in Supabase Dashboard
2. Create a new function
3. Add CORS headers in the function response
4. Update your game to call the edge function instead of the REST API

## Testing Locally

Local builds don't have CORS restrictions, which is why it works on your computer but not on GitHub Pages.

To test the CORS fix:
1. Deploy to GitHub Pages after configuring CORS
2. Or use browser extensions to disable CORS (only for testing!)
3. Or run a local web server and access via localhost

## More Information

- Supabase CORS docs: https://supabase.com/docs/guides/api/cors
- MDN CORS Guide: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS

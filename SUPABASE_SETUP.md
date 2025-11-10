# Supabase Setup Instructions

## Step 1: Get Your Supabase Credentials

1. Go to [Supabase Dashboard](https://app.supabase.com/)
2. Select your project
3. Click on the **Settings** icon (⚙️) in the left sidebar
4. Click on **API** in the settings menu
5. Copy the following values:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon/public key** (the `anon` key under "Project API keys")

## Step 2: Add Credentials to Your App

Open `lib/config/supabase_config.dart` and replace:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

With your actual values:

```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';
static const String supabaseAnonKey = 'eyJhbGc...your_actual_key';
```

## Step 3: Configure Storage Bucket Permissions

1. In Supabase Dashboard, go to **Storage**
2. Click on your `user-images` bucket
3. Click on **Policies** tab
4. Add a new policy with these settings:
   - **Policy Name**: "Allow public uploads"
   - **Allowed operation**: INSERT
   - **Target roles**: public
   - **Policy definition**: `true` (or customize as needed)

5. Add another policy for public access:
   - **Policy Name**: "Allow public downloads"
   - **Allowed operation**: SELECT
   - **Target roles**: public
   - **Policy definition**: `true`

Alternatively, you can make the bucket public:
- Go to Storage → user-images
- Click the 3 dots menu → "Edit bucket"
- Toggle "Public bucket" ON

## Step 4: Test the Upload

1. Hot restart your Flutter app
2. Go to the Register screen
3. Select an image
4. Fill in all required fields
5. Click "Sign Up"
6. Check your Supabase Storage dashboard to see the uploaded image!

## How It Works

When a user registers:
1. Image is selected using `image_picker`
2. Image bytes are read (works on both web and mobile)
3. Image is uploaded to Supabase Storage with a unique timestamp filename
4. A public URL is generated for the uploaded image
5. This URL can be saved to your database along with user info

## Image URL Format

The uploaded images will be accessible at:
```
https://xxxxx.supabase.co/storage/v1/object/public/user-images/[filename]
```

You can use this URL to display the image anywhere in your app or share it with others.

## Troubleshooting

**Error: "new row violates row-level security policy"**
- Make sure you've set up the storage policies correctly (Step 3)

**Error: "Invalid API key"**
- Double-check your credentials in `supabase_config.dart`
- Make sure you're using the `anon` key, not the `service_role` key

**Image not uploading**
- Check console for error messages
- Verify the bucket name is exactly `user-images`
- Ensure you have an active internet connection

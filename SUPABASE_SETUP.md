# Supabase Leaderboard Setup

## Step 1: Create the Leaderboard Table

Go to your Supabase project dashboard and navigate to the **SQL Editor**.

Run this SQL command:

```sql
-- Create leaderboard table
CREATE TABLE leaderboard (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  score INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on score for fast sorting
CREATE INDEX idx_leaderboard_score ON leaderboard(score DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE leaderboard ENABLE ROW LEVEL SECURITY;

-- Create policy to allow anyone to read leaderboard
CREATE POLICY "Allow public read access"
  ON leaderboard
  FOR SELECT
  TO public
  USING (true);

-- Create policy to allow anyone to insert scores
CREATE POLICY "Allow public insert access"
  ON leaderboard
  FOR INSERT
  TO public
  WITH CHECK (true);
```

## Step 2: Verify Table Setup

1. Go to **Table Editor** in Supabase dashboard
2. You should see a table named `leaderboard` with columns:
   - `id` (bigint, primary key)
   - `name` (text)
   - `score` (integer)
   - `created_at` (timestamp)

## Step 3: Test the Connection

The Godot game will automatically connect to Supabase when it starts. Check the Godot console output for:
- "Fetching leaderboard from Supabase..."
- "Loaded X leaderboard entries from Supabase"

## Optional: Add Test Data

You can manually add some test scores:

```sql
INSERT INTO leaderboard (name, score) VALUES
  ('ALICE', 5000),
  ('BOB', 4500),
  ('CHARLIE', 4000);
```

## Security Notes

- The current setup allows anyone to read and insert scores
- To prevent abuse, you could add rate limiting or require authentication
- For production, consider adding server-side validation

## API Endpoints Used

- **GET** `/rest/v1/leaderboard?select=*&order=score.desc&limit=10` - Fetch top 10
- **POST** `/rest/v1/leaderboard` - Submit new score

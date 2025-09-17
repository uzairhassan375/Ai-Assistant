# Environment Setup Instructions

## Setting up the Gemini API Key

### 1. Get your Gemini API Key
- Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
- Sign in with your Google account
- Create a new API key
- Copy the generated API key

### 2. Configure the .env file
- Open the `.env` file in the root directory of the project
- Replace `your_actual_gemini_api_key_here` with your actual API key
- Save the file

Example:
```
GEMINI_API_KEY=AIzaSyABC123def456ghi789jkl012mno345pqr678stu
```

### 3. Security Notes
- **Never commit the `.env` file to version control**
- The `.env` file is already added to `.gitignore` for security
- Keep your API key private and don't share it publicly
- If you accidentally expose your API key, regenerate a new one immediately

### 4. Usage
The app will automatically load the API key from the `.env` file when it starts. If the API key is missing or invalid, you'll see an error message in the app.

### 5. Troubleshooting
- Make sure the `.env` file is in the root directory (same level as `pubspec.yaml`)
- Ensure there are no extra spaces around the API key
- Restart the app after updating the `.env` file
- Check that the API key is valid and has the necessary permissions

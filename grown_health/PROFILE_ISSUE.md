# Profile Data Not Showing Issue

## Problem
Personal information (age, gender, weight, height) is saved in the database but not showing in the app's profile screen.

## Root Cause
The backend has **TWO different profile storage systems**:

1. **Users Collection** (where data is actually stored):
   ```json
   {
     "email": "dumb@gmail.com",
     "name": "",
     "gender": "male",
     "age": 44,
     "height": 177,
     "weight": 77,
     "profileCompleted": false
   }
   ```

2. **Profiles Collection** (where the Profile API expects data):
   - This collection doesn't have documents for users
   - The Profile API (`GET /api/profile/`) reads from this collection
   - Returns null/empty for age, gender, weight, height

## The Issue
- `POST /api/profile/complete` saves data to `users` collection
- `GET /api/profile/` reads from `profiles` collection
- **Data is in the wrong collection!**

## Backend Fix Required

### Option 1: Update Profile Complete Endpoint
Change `POST /api/profile/complete` to create/update a document in the `profiles` collection:

```javascript
// In the profile complete endpoint
const profile = await Profile.create({
  userId: req.user._id,
  email: req.user.email,
  name: req.body.name,
  age: req.body.age,
  gender: req.body.gender,
  weight: req.body.weight,
  height: req.body.height,
  isProfileComplete: true
});
```

### Option 2: Update Profile GET Endpoint
Change `GET /api/profile/` to read from the `users` collection:

```javascript
// In the get profile endpoint
const user = await User.findById(req.user._id);
return {
  email: user.email,
  name: user.name,
  age: user.age,
  gender: user.gender,
  weight: user.weight,
  height: user.height,
  profileImage: user.profileImage,
  isProfileComplete: user.profileCompleted
};
```

## Current Behavior
- ✅ Name shows correctly (from users collection)
- ✅ Email shows correctly (from auth)
- ❌ Age shows "Not set" (null from profiles collection)
- ❌ Gender shows "Not set" (null from profiles collection)
- ❌ Weight shows "Not set" (null from profiles collection)
- ❌ Height shows "Not set" (null from profiles collection)

## Expected Behavior
All fields should show the values from the database:
- Age: 44 years
- Gender: male
- Weight: 77 kg
- Height: 177 cm

## Temporary Frontend Workaround
We could create a custom endpoint or modify the app to read directly from the user data, but this is not recommended as it bypasses the intended API structure.

## Recommendation
**Fix the backend** to ensure data consistency between the two collections.

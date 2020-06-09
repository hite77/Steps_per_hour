# stepsperhour

Displays goal steps per hour, your current steps for the day from fitbit.

## Flutter plugins used

- clock -- used to detect day change and reset offset each day and only show current hour and onward
- flutter_web_auth -- plugin for oauth authentication
- http -- used to perform fitbit requests, and get tokens using authentication, and refresh tokens

## Android Manifest

- Add the following to both the debug manifest and release manifest

    <uses-permission android:name="android.permission.INTERNET"/>

- The following is in the release manifest, it allows oauth to feed into the auth plugin.  The callback should be updated to what you entered into fitbit New App

          <activity android:name="com.linusu.flutter_web_auth.CallbackActivity" >
              <intent-filter android:label="flutter_web_auth">
                  <action android:name="android.intent.action.VIEW" />
                  <category android:name="android.intent.category.DEFAULT" />
                  <category android:name="android.intent.category.BROWSABLE" />
                  <data android:scheme="com.test.app" />
              </intent-filter>
          </activity>

## Secrets File

- Use link below to register an app, and copy the clientId and clientSecret to file below
- [Register New App](https://dev.fitbit.com/apps/new)
- The clientId and secret will be accessible to the app.

Contents of file:

    {
        "client_id": "<your fitbit apps clientId>"
        "client_secret": "<your fitbit apps clientSecret>"
    }

## Weight

    curl -i -H "Authorization: Bearer <Access_Token>" \
        -H "Accept-Language: en_US" \
        -H "Accept-Local: en_US"  \
        https://api.fitbit.com/1/user/-/body/log/weight/date/2020-01-01.json

- Pulls pounds and other info for specific date
- Can call with date and also indicate a time period of up to 1month.
- Will need to pull for time period, and get into series data for graphing.
- Likely set to at least a month, or if more then call multiple times.
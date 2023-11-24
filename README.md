# Microsoft Ignite Deck Download
Simple script to download decks from [Microsoft Ignite](https://ignite.microsoft.com/en-US/home) sessions.
API URL: [https://api.ignite.microsoft.com/api/session/all/en-US](https://api.ignite.microsoft.com/api/session/all/en-US)
<br>
Session Deck download link can be found in key _slideDeck_
![image](assets/api.png)
<br>
## Usage
Download All Decks
```
./MSIgnite2023Nov-Download-Resources.ps1
```
<br>
Download specific sessions
```
./MSIgnite2023Nov-Download-Resources.ps1 -sessionCodes "BRK403,BRK404"
```
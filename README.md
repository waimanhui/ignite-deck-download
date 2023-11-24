# Microsoft Ignite Deck Download
Simple script to download decks from [Microsoft Ignite](https://ignite.microsoft.com/en-US/home) sessions.<br><br>
API URL: [https://api.ignite.microsoft.com/api/session/all/en-US](https://api.ignite.microsoft.com/api/session/all/en-US)
<br><br>
Session Deck download link can be found in key _slideDeck_
![image](assets/api.png)
<br>
## Usage

Download all decks
```
./MSIgnite2023Nov-Download-Resources.ps1
```
Download specific session decks
```
./MSIgnite2023Nov-Download-Resources.ps1 -sessionCodes "BRK403,BRK404"
```

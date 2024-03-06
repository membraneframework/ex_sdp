# Fixtures

All files were generated with the following code:

```js
pc = new RTCPeerConnection();
pc.addTransceiver("audio");
pc.addTransceiver("video");
await pc.createOffer();
```

Additionally, the line "a=fmtp:45 profile=1" was added for AV1 codec in chromium SDP offer.

Browsers used:
* Chromium - 121.0.6167.139
* Firefox - 122.0
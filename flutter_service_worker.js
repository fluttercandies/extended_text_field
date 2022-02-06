'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  "version.json": "ff966ab969ba381b900e61629bfb9789",
"index.html": "886e4292f5df2fd2ec2ddb6fd2350ad6",
"/": "886e4292f5df2fd2ec2ddb6fd2350ad6",
"main.dart.js": "f86f10bea937788230e3238e7bebfb16",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "0867c3e13649ac4d06fe34b7b3ddce08",
"assets/AssetManifest.json": "fd894feacfcdfa741e74cbb97ad723e6",
"assets/NOTICES": "93bfef9f7bc8a0b8a4298777c19dd797",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "6d342eb68f170c97609e9da345464e5e",
"assets/packages/loading_more_list/assets/empty.jpeg": "52a69bab9f87bcf0052d8e55ea314977",
"assets/fonts/MaterialIcons-Regular.otf": "4e6447691c9509f7acdbf8a931a85ca1",
"assets/assets/48.png": "6fb7e22faec6e422bdf4fe82ce33b68f",
"assets/assets/8.png": "aaf574f801502c501fe70e1a0c1ff424",
"assets/assets/9.png": "76558397b4441e15177408b139744022",
"assets/assets/14.png": "3ef560eea70cdf96e3d5a2437c121527",
"assets/assets/28.png": "9f67b32aefa54339a926ea13f403647f",
"assets/assets/29.png": "abd38886c53394a4f42d972ee99a8b90",
"assets/assets/15.png": "6ea855cc8b6732c4a323cc1ab5810366",
"assets/assets/17.png": "9c9b78a0d585029d6a6dcb7727ff46e4",
"assets/assets/16.png": "4fc704a7ea50713110113c486be0ba0e",
"assets/assets/12.png": "9e8100c4be24d1e86a2564f9a1afcfdf",
"assets/assets/13.png": "3314732fa9e14d20f00c941c56c27227",
"assets/assets/39.png": "b8e2368130cdf6a6d900f1474494ee3f",
"assets/assets/11.png": "0fd8ec62cb3cd082c71f665df01f2a86",
"assets/assets/10.png": "ff8ec4596f0368120a606f7c21f666c3",
"assets/assets/38.png": "59c24810c5c47de89fea4210df43eb39",
"assets/assets/35.png": "7bc95842118bb202cdf24712c39bcebf",
"assets/assets/21.png": "651a72acffbc9cf38238206da9514cdf",
"assets/assets/20.png": "90b857ed38e7eeeae777ecf053eaa597",
"assets/assets/34.png": "44ed06adc72088755c5eeee954ad2c74",
"assets/assets/flutter_candies_logo.png": "be4d473295d5af30e6af6cdcac3799bb",
"assets/assets/22.png": "2b7ac1d076451d60fa1b02a7efea6185",
"assets/assets/36.png": "a600c2f2802304dfc6a859446ef5f51d",
"assets/assets/37.png": "c98e7e4f8b56aef18c38d023f5a623cc",
"assets/assets/23.png": "c18daffc298717f6d0897a4e588c816b",
"assets/assets/27.png": "ad0967c3f498b6beece8877e19c648d2",
"assets/assets/33.png": "41578736a209c1be690e4b10bf88c6f6",
"assets/assets/32.png": "fdfb0c36986042430fcdd2842328e61d",
"assets/assets/26.png": "3d877bf5cf210a8bf92b3ca8687bc4a6",
"assets/assets/18.png": "5eed4a5880aefd1592871f2219e4973a",
"assets/assets/30.png": "a585ea542fff6abd24ab6ad7115475a6",
"assets/assets/24.png": "a10a45fc8db99258c390750a832d91d7",
"assets/assets/25.png": "a1deac45fe31bb4516339169800c02d4",
"assets/assets/31.png": "cbb1033969bc78f5759d953f824c53b3",
"assets/assets/19.png": "52f3dd1a7d0cddad9698013e289a9e27",
"assets/assets/4.png": "3cf15d48af2193b09f28ea52c8bbd40c",
"assets/assets/42.png": "d50e3a7047764aedf589d22cb92e3cbc",
"assets/assets/43.png": "2175ed492d8103fe1164f414d9da7b4b",
"assets/assets/5.png": "d4bf4a58d80127afedbfa97712184d36",
"assets/assets/41.png": "fd7a3cb211a3a9c0c3edb6bbdbf092c2",
"assets/assets/7.png": "76ffaf41abb154f4fd0a1561a2fe081a",
"assets/assets/6.png": "059eccac96fae2557ae8e202aa09fa5e",
"assets/assets/40.png": "d31f4ff6176bedac2101b1cbb9083f36",
"assets/assets/44.png": "650c85706c345b5689d47da4c511772f",
"assets/assets/2.png": "25672c69769e45c8592c359790f642ba",
"assets/assets/3.png": "a9a21d5f825ec402aaf85fb6afd16960",
"assets/assets/45.png": "76abffcfdf43905dd0541bae0641c1dc",
"assets/assets/1.png": "b4e5366592c909e9fc5187196dec701b",
"assets/assets/47.png": "8f4e97eff324f38d7645f23e7cb389d8",
"assets/assets/46.png": "8f1f027c12ef3db193f5deb8bd3e41d3",
"canvaskit/canvaskit.js": "62b9906717d7215a6ff4cc24efbd1b5c",
"canvaskit/profiling/canvaskit.js": "3783918f48ef691e230156c251169480",
"canvaskit/profiling/canvaskit.wasm": "6d1b0fc1ec88c3110db88caa3393c580",
"canvaskit/canvaskit.wasm": "b179ba02b7a9f61ebc108f82c5a1ecdb"
};

// The application shell files that are downloaded before a service worker can
// start.
const CORE = [
  "/",
"main.dart.js",
"index.html",
"assets/NOTICES",
"assets/AssetManifest.json",
"assets/FontManifest.json"];
// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});

// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});

// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache.
        return response || fetch(event.request).then((response) => {
          cache.put(event.request, response.clone());
          return response;
        });
      })
    })
  );
});

self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});

// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}

// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}

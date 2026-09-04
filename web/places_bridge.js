(function () {
  var loadPromise = null;
  var cachedApiKey = null;

  window.safarsurePlacesLoad = function (apiKey) {
    if (!apiKey) {
      return Promise.resolve();
    }
    cachedApiKey = apiKey;
    if (loadPromise) {
      return loadPromise;
    }
    loadPromise = new Promise(function (resolve, reject) {
      if (window.google && window.google.maps && window.google.maps.importLibrary) {
        resolve();
        return;
      }
      var script = document.createElement('script');
      script.src =
        'https://maps.googleapis.com/maps/api/js?key=' +
        encodeURIComponent(apiKey) +
        '&loading=async';
      script.async = true;
      script.defer = true;
      script.onload = function () {
        resolve();
      };
      script.onerror = function (err) {
        reject(err);
      };
      document.head.appendChild(script);
    });
    return loadPromise;
  };

  window.safarsurePlacesAutocomplete = function (query, callback) {
    var finish = function (payload) {
      callback(payload);
    };

    if (!cachedApiKey) {
      finish({ suggestions: [], error: 'PERMISSION_DENIED' });
      return;
    }

    window
      .safarsurePlacesLoad(cachedApiKey)
      .then(function () {
        return google.maps.importLibrary('places');
      })
      .then(function (placesLib) {
        var AutocompleteSuggestion = placesLib.AutocompleteSuggestion;
        return AutocompleteSuggestion.fetchAutocompleteSuggestions({
          input: query,
          includedRegionCodes: ['in'],
          language: 'en',
        });
      })
      .then(function (response) {
        var suggestions = (response.suggestions || [])
          .map(function (s) {
            var prediction = s.placePrediction;
            if (!prediction || !prediction.text) return null;
            return {
              description: prediction.text.toString(),
              placeId: prediction.placeId || '',
            };
          })
          .filter(function (item) {
            return item !== null;
          });
        finish({ suggestions: suggestions, error: null });
      })
      .catch(function (err) {
        var message =
          (err && err.message) ||
          (typeof err === 'string' ? err : 'REQUEST_DENIED');
        finish({ suggestions: [], error: message });
      });
  };
})();

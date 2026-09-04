(function () {
  var service = null;
  var loadPromise = null;

  function ensureService() {
    return service;
  }

  window.safarsurePlacesLoad = function (apiKey) {
    if (!apiKey) {
      return Promise.resolve();
    }
    if (loadPromise) {
      return loadPromise;
    }
    loadPromise = new Promise(function (resolve, reject) {
      if (
        window.google &&
        window.google.maps &&
        window.google.maps.places &&
        window.google.maps.places.AutocompleteService
      ) {
        service = new google.maps.places.AutocompleteService();
        resolve();
        return;
      }
      var script = document.createElement('script');
      script.src =
        'https://maps.googleapis.com/maps/api/js?key=' +
        encodeURIComponent(apiKey) +
        '&libraries=places';
      script.async = true;
      script.defer = true;
      script.onload = function () {
        service = new google.maps.places.AutocompleteService();
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
    if (!service) {
      callback([]);
      return;
    }
    service.getPlacePredictions(
      {
        input: query,
        componentRestrictions: { country: 'in' },
      },
      function (predictions, status) {
        if (
          status !== google.maps.places.PlacesServiceStatus.OK ||
          !predictions
        ) {
          callback([]);
          return;
        }
        callback(
          predictions.map(function (p) {
            return {
              description: p.description,
              placeId: p.place_id,
            };
          })
        );
      }
    );
  };
})();

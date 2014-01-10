# ftoggle

This is a node library that implements an API and config format for enabling feature toggling and/or A/B testing.  The idea being, you combine configuration with per-request data (e.g. cookies, HTTP headers, etc.) in order to turn bits of the application on or off.

## Usage

ftoggle is implemented as Express middleware. Toggles are nestable (this is more useful for A/B testing; should be used in moderation).

```
var config = {
  version: 1
  features: {
    feature_1: {
      traffic: 0.5
    },
    feature_2: {
      traffic: 0.3,
      features: {
        subfeature_2_1: {
          traffic: 0
        },
        subfeature_2_2: {
          traffic: 1 
        }
      }
    }
  }
};

var ftoggle = require('ftoggle').makeFtoggle();
ftoggle.setConfig(config);

// ...

app.use(ftoggle.newMiddleware());

```

You can call ```ftoggle.isFeatureEnabled``` in your request handlers:

```
if (req.ftoggle.isFeatureEnabled('feature_1')) { ...
```

For hierarchical/nested feature toggles:

```
if (req.ftoggle.isFeatureEnabled('feature_2.subfeature_2_1')) { ...
```

## TODO

 * Fetcher/updater for config data. Will fetch remotely, poll periodically, update config without client intervention.
 * Persistence via cookies
 * Pass-through via headers
 * Override via cookies
 * Override via headers


# ftoggle

This is a node library that implements an API and config format for enabling feature toggling and/or A/B testing.  The idea being, you combine configuration with per-request data (e.g. cookies, HTTP headers, etc.) in order to turn bits of the application on or off.

## Usage

ftoggle is implemented as Express middleware. Toggles are nestable (this is more useful for A/B testing; should be used in moderation).

```
var config = {
  version: 1,
  name: "somelabel",
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

var FeatureToggle = require('ftoggle');
var ftoggle = new FeatureToggle();
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

If you want to dispatch to some callbacks:

```
req.ftoggole.isFeatureEnabled('feature_1', yesFunction, noFunction);
```

You can opt into or out of features with a query parameter:

```
http://foo.bar.com/?ftoggle-$configname-on=f1,f2,f3&ftoggle-$configname-off=f4,f5,f6
```

## Client/Browser Usage

manta-frontend does some magic to use the lib/request-decoration.coffee code on the client side. It provides both an instantiatable object, and an Angular service. Consult that code for more detail.

## TODO

 * Fetcher/updater for config data. Will fetch remotely, poll periodically, update config without client intervention.

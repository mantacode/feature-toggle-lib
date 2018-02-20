# ftoggle

This is a node library that implements an API and config format for enabling feature toggling and/or A/B testing.  The idea being, you combine configuration with per-request data (e.g. cookies) in order to turn bits of the application on or off.

## Usage

`feature-toggle-lib` exports a single class, `FeatureToggle`, that represents your generic config. For each user (typically an http request on the server), you should create an instance of `Ftoggle` (a particular user's settings within the global config) via `featureToggleInstance.create()`.

Features have traffic between 0 and 1 (where 0 means no traffic and 1 means all traffic) that indicate how toggles should be set for a user (using `Math.random`). Features are nestable and recursively calculated (which is useful for A/B testing).

Example config:

```js
const config = {
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
```

Example (simplified) setup using express:

```js
const express = require('express');
const app = express();
const FeatureToggle = require('feature-toggle-lib');
const config = require('./config/ftoggle.js')
const ftoggle = new FeatureToggle(config);

// Or
// ftoggle.setConfig(config);

// Initialize the ftoggle settings for this user
app.use((req, res, next) => {
  req.ftoggle = ftoggle.create(req.cookies.ftoggle_cookie);
  next();
});

// All your normal middleware
// ...

// Write the ftoggle cookie so this user keeps their current settings across pages
app.use((req, res, next) => {
  res.cookie(req.ftoggle.toggleName, req.ftoggle.serialize, { maxAge: 31536000000 });
  next();
});
```

## FeatureToggle API

### new FeatureToggle([config])

Create an instance of `FeatureToggle`.

- config - A config object containing the features to toggle a user into and out of. Ftoggle recognizes the following properties in a config object:
  - config.name - Top level only. The name of the config, which can be used to set a unique cookie. This allows you to use multiple ftoggle configs with different names, if necessary.
  - config.version - Top level only. The version of the config. When a user with an existing ftoggle config matching `config.name` comes in, if the version in that config does not match this value, the config is recalculated (i.e. the user's toggles are updated to the current config).
  - config.features - A set of key/value pairs where the key is the feature name and the value is a sub-instance of `config` (but without `name` and `version`). That is, the value can (recursively) have all the same keys outlined here except `name` and `version` (technically it can still have those but they will be ignored).
  - config.traffic - The amount of traffic this feature should receive. Note, the top level _does_ also have this field and setting it to anything less than 1 means some traffic will be toggled into _anything_. To make an abTest, create a feature with `exclusiveSplit` (see below) that receives some portion of traffic (it's up to you whether this is _all_ traffic or some subset), and within that, create the various test versions with traffic that totals 1. So you might have a `control` feature with traffic `0.34`, a `test_a` feature with traffic `0.33`, and a `test_b` feature with traffic `0.33`.
  - config.exclusiveSplit - Normally, traffic for a feature is calculated indepently of all other features, so if there are multiple top-level features with traffic `1`, they will all be turned on. Setting `exclusiveSplit` signals `ftoggle` that only _one_ feature at a particular level should be turned on. In an A/B test, for example, you only want the user to be toggled into _one_ of the test versions. For example:
    ```js
    {
      features: {
        someTest: {
          traffic: 1, // All user's get one of these features
          exclusiveSplit: true, // and ONLY one of these features
          features: {
            control: {
              traffic: 0.34 // 34% of traffic
            },
            test_a: {
              traffic: 0.33 // 33% of traffic
            }
            test_b: {
              traffic: 0.33 // 33% of traffic
            }
          }
        }
      }
    }
    ```

    It is not _strictly_ necessary that traffic total 100% (or `1`), but if it's less than 100%, some user's will end up in none of the features, and if it's more, the excess will be ignored effectively _making_ it total 100%. I.e. probably just don't do that.
  - config.settings - Ftoggle supports setting flags based on which features a user is toggled into. These are merged into a single `settings` object accessible via `ftoggle.settings` or `ftoggle.getSettings()`. For example:
    ```js
    {
      settings: {
        fooEnabled: false,
        barEnabled: false
      },
      traffic: 1,
      features: {
        foo: {
          traffic: 1,
          settings: {
            fooEnabled: true
          }
        },
        bar: {
          traffic: 0
          settings: {
            barEnabled: true
          }
        }
      }
    }
    ```
    Here, `settings` will be `{ fooEnabled: true, barEnabled: false }` because the feature `foo` will be toggled on and the `fooEnabled` setting will be enabled, but the feature `bar` will _not_ be toggled on and therefore the `barEnabled` setting will not be enabled. We recommend _only_ using `settings` for conditional logic, as opposed to `isFeatureEnabled` or `findEnabledChildren` or `ftoggle.toggles`. There are two reasons for this. First, it's significantly more clear (semantically) to say `if (ftoggle.settings.fooEnabled)` than `if (ftoggle.toggles.foo.e)` or `if (ftoggle.isFeatureEnabled('foo'))` and second, it allows you to reuse settings in different features, so you can say `if (ftoggle.settings.extremeVersion)` instead of `if (ftoggle.settings.abTests.extreme.extreme_a || ftoggle.settings.abTests.extreme.extreme_b)`.

### featureToggleInstance.create([serialization])

Create a user-specific config instance. Uses the existing serialization if present. Returns an instance of `Ftoggle`.

- serialization - A previously calculated ftoggle configuration, in the form version + z + config + z + extra bits.

### setConfig(config)

Set the config for this feature toggle lib instance. You can pass this into the constructor as well, but you might use this function if you're storing your config remotely (e.g. s3), and updating it occasionally from a polling function.

- config - A config object containing the features to toggle a user into and out of.

### addConfig(config)

Merge new configuration in with existing. You might use this if you want to separate parts of your configuration files for clarity. For instance, we use to keep all toggles and traffic in one file and settings for various buckets in several other files, and then merge them all together using this function.

- config - A config object containing the features to toggle a user into and out of. Note that the key/value heirarchy must be the same in your configs for this to work correctly. That is, if you want to separate out your `settings`, you still need to put them in the right object path, like:
  ```js
  { features: { foo: { features: { bar: {
    settings: {
      giveMeSomeFoo: true,
      andSomeBar: true
    }
  }}}}}
  ```

## Ftoggle API

### new Ftoggle(toggles, settings, featureConfig)

Create a new user-specific ftoggle instance.

- toggles - An object of enabled and disabled features in the form:
  ```js
  {
    v: 12,
    foo: {
      bar: {
        e: 1
      },
      baz: {
        e: 0
      }
    }
  }
  ```
- settings - An object of flags enabled (or disabled) by the toggles above, in the form:
  ```js
  {
    firstThingOn: true,
    secondThingOn: false
  }
  ```
- featureConfig - The original config used to create the `FeatureToggle` instance. This is used for calculating/recalculating manually enabled and disabled features (see [.enable](#enable) and [.disable](#disable)

### isFeatureEnabled(featurePath)

Determine with a particular feature is on or off.

- featurePath - A dot-notated path to a toggle.

Example:

```js
ftoggle.isFeatureEnabled('foo.bar'); // -> true
```

### findEnabledChildren(parentPath)

Get a list of subfeatures enabled beneath `parentPath`.

- parentPath - The feature path to inspect.

Example:

```js
ftoggle.findEnabledChildren('foo.bar'); // -> ['bar', 'quux']
```

### doesFeatureExist(featurePath)

Check whether a particular feature exists in the config.

- featurePath - A dot-notated path to a toggle.

Example:

```js
ftoggle.doesFeatureExist('foo.bar'); // -> true
```

### getToggles()

Returns the complete toggles object (same as using `ftoggle.toggles`).

### getSetting(key)

Get the value of a particular setting.

- key - The setting name.

Example:

```js
ftoggle.getSetting('allYourBaseAreBelongToUs'); // -> "someone set up us the bomb"
```

### getSettings()

Get all settings (same as using `ftoggle.settings`).

### getSettingsForFeature(featurePath)

Get the raw non-toggle-specific settings for a feature path.

- featurePath - A dot-notated path to a toggle.

Example:

```js
ftoggle.getSettingsForFeature('foo.bar') // -> { 'fooBarEnabled': true }
```

### setFeatureSettings(featurePath)

Add the settings under `featurePath` to the `settings` object as if those features were toggled on.

- featurePath - A dot-notated path to a toggle.

Example:

```js
ftoggle.setFeatureSettings('foo.bar');
```

### unsetFeatureSettings(featurePath)

Delete settings under `featurePath` from the `settings` object. Note that this does _not_ reset those settings to parent level settings, which is a good reason to always make your defaults falsy.

- featurePath - A dot-notated path to a toggle.

```js
ftoggle.unsetFeatureSettings('foo.bar');
```

### enable(featurePath)

Enable a feature on the fly, including setting all of it's settings in the `settings` object. Sometimes you want to use something _other_ than randomization for determining particular site logic. E.g. you might want to enable a particular flag for users who come to your site from a particular referer. This function allows you to do that.

- featurePath - A dot-notated path to a toggle.

Example:

```js
ftoggle.enable('abTests.ppc_checkout');
```

### enableAll(features)

Enable a list of feature. This is just sugar for calling `enable` on each feature individually.

- features - An array or comma-separated list of feature paths.

Example:

```js
ftoggle.enableAll(['foo', 'bar']);

//or
ftoggle.enableAll('foo,bar');
```

### disable(featurePath)

Disable a feaure on the fly, including unsetting all of it's settings in the `settings` object. The reverse of `enable` above.

- featurePath - A dot-notated path to a toggle.

Example:

```js
ftoggle.disable('foo.bar');
```

### disableAll(features)

Disable a list of features. Like `enableAll`, this is sugar for calling `disable` on each feature.

- features - An array or comma-separated list of feature paths.

Example:

```js
ftoggle.disableAll('foo', 'bar');

// or
ftoggle.disableAll('foo,bar');
```

### makeFeaturePath(shortPath)

Most ftoggle function make use of short paths (e.g. foo.bar.baz) because that's how the toggles object is shaped. However, the original feature config always has a `features` object at each level. This simple utitlity converts a path usable on the `toggles` object to one usable on the `featureConfig` object.

- shortPath - A dot-notated path to a toggle.

Example:

```js
ftoggle.makeFeaturePath('foo.bar'); // -> features.foo.features.bar
```

### getAllChildNodes(featureConfig, key)

Get a list of all child nodes under a particular feature.

- featureConfig - Any level (top or nested) of a feature config.
- key - The feature to return child nodes of.

Example:

```js
ftoggle.getAllChildNodes(mainConfig, 'foo');
// -> ['bar', 'bar.features.baz', 'bar.features.quux']
```

### unsetAll(toggleObject)

Recursively change `e: 1` to `e: 0` in a partial (or whole) toggle object.

- toggleObject - The portion of the toggle object to change.

Example:

```js
ftoggle.unsetAll(ftoggle.toggles.abTests);
```

### serialize()

Ftoggle uses a packed bit algorithm to calculate small string value representing a user's toggles. Use this value to preserve toggles across pages, by persisting it in, for example, a cookie or a redis store or memcached or some other session manager or a database (etc.).

Example:

```js
ftoggle.serialize()
```

### static deserialize(serialization, toggles)

Unpack a serialization into a set of toggles. Because this requires a toggle object, it's much easier to call `feautreToggle.create(serialization)` instead.

- serialization - The output from a previous call to `.serialize()`.
- toggles - A fresh toggle object. Note that this is only used to know what toggles exist. The values are ignored/overwritten by the values in the serialization.

Example:

```js
ftoggle.deserialize(req.cookies.ftoggle, toggle);
```

## Client/Browser Usage

There are two files in `dist` that you can include in a frontend bundle: `dist/ftoggle.js` which includes it's own version of lodash and `dist/ftoggle-standalone.js` which does _not_ and relies on lodash being available on window. If you're already using lodash in your client bundle, use the standalone version to prevent multiple copies of lodash being bundled.

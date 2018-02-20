module.exports = {
  version: 2,
  name: 'test',
  settings: {
    topEnabled: true
  },
  features: {
    foo: {
      traffic: 1,
      settings: {
        fooEnabled: true
      }
    },
    bar: {
      traffic: 0,
      settings: {
        barEnabled: true
      }
    },
    treatments: {
      exclusiveSplit: 1,
      traffic: 1,
      settings: {
        treatmentsEnabled: true,
        topOfSplitEnabled: true
      },
      features: {
        treatment_a: {
          traffic: 0.5,
          settings: {
            treatmentAEnabled: true
          }
        },
        treatment_b: {
          traffic: 0.5,
          settings: {
            treatmentBEnabled: true,
            topOfSplitEnabled: false
          }
        }
      }
    },
    fruits: {
      exclusiveSplit: 1,
      traffic: 0,
      settings: {
        fruitsEnabled: true
      },
      features: {
        banana: {
          exclusiveSplit: true,
          traffic: 0.5,
          settings: {
            bananaEnabled: true
          },
          features: {
            yellow_banana: {
              traffic: 0.5,
              settings: {
                yelloBananaEnabled: true,
                greenBananaEnabled: false
              }
            },
            green_banana: {
              traffic: 0.5,
              settings: {
                greenBananaEnabled: true,
                yellowBananaEnabled: false
              }
            }
          }
        },
        apple: {
          exclusiveSplit: true,
          traffic: 0.5,
          settings: { 
            appleEnabled: true
          },
          features: {
            green_apple: {
              traffic: 0.5,
              settings: {
                greenAppleEnabled: true,
                redAppleEnabled: false
              }
            },
            red_apple: {
              traffic: 0.5,
              settings: {
                redAppleEnabled: true,
                greenAppleEnabled: false
              }
            }
          }
        }
      }
    }
  }
};

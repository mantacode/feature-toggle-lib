module.exports = {
  version: 2,
  name: 'test',
  conf: {
    topEnabled: true
  },
  features: {
    foo: {
      traffic: 1,
      conf: {
        fooEnabled: true
      }
    },
    bar: {
      traffic: 0,
      conf: {
        barEnabled: true
      }
    },
    treatments: {
      exclusiveSplit: 1,
      traffic: 1,
      conf: {
        treatmentsEnabled: true,
        topOfSplitEnabled: true
      },
      features: {
        treatment_a: {
          traffic: 0.5,
          conf: {
            treatmentAEnabled: true
          }
        },
        treatment_b: {
          traffic: 0.5,
          conf: {
            treatmentBEnabled: true,
            topOfSplitEnabled: false
          }
        }
      }
    },
    fruits: {
      exclusiveSplit: 1,
      traffic: 0,
      conf: {
        fruitsEnabled: true
      },
      features: {
        banana: {
          exclusiveSplit: true,
          traffic: 0.5,
          conf: {
            bananaEnabled: true
          },
          features: {
            yellow_banana: {
              traffic: 0.5,
              conf: {
                yelloBananaEnabled: true,
                greenBananaEnabled: false
              }
            },
            green_banana: {
              traffic: 0.5,
              conf: {
                greenBananaEnabled: true,
                yellowBananaEnabled: false
              }
            }
          }
        },
        apple: {
          exclusiveSplit: true,
          traffic: 0.5,
          conf: { 
            appleEnabled: true
          },
          features: {
            green_apple: {
              traffic: 0.5,
              conf: {
                greenAppleEnabled: true,
                redAppleEnabled: false
              }
            },
            red_apple: {
              traffic: 0.5,
              conf: {
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

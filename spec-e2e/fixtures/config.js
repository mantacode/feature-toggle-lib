module.exports = {
  settings: {
    topEnabled: true
  },
  features: {
    foo: {
      settings: {
        fooEnabled: true
      }
    },
    bar: {
      settings: {
        barEnabled: true
      }
    },
    treatments: {
      settings: {
        treatmentsEnabled: true,
        topOfSplitEnabled: true
      },
      features: {
        treatment_a: {
          settings: {
            treatmentAEnabled: true
          }
        },
        treatment_b: {
          settings: {
            treatmentBEnabled: true,
            topOfSplitEnabled: false
          }
        }
      }
    },
    fruits: {
      settings: {
        fruitsEnabled: true
      },
      features: {
        banana: {
          settings: {
            bananaEnabled: true
          },
          features: {
            yellow_banana: {
              settings: {
                yelloBananaEnabled: true,
                greenBananaEnabled: false
              }
            },
            green_banana: {
              settings: {
                greenBananaEnabled: true,
                yellowBananaEnabled: false
              }
            }
          }
        },
        apple: {
          settings: { 
            appleEnabled: true
          },
          features: {
            green_apple: {
              settings: {
                greenAppleEnabled: true,
                redAppleEnabled: false
              }
            },
            red_apple: {
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

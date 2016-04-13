module.exports = {
  conf: {
    topEnabled: true
  },
  features: {
    foo: {
      conf: {
        fooEnabled: true
      }
    },
    bar: {
      conf: {
        barEnabled: true
      }
    },
    treatments: {
      conf: {
        treatmentsEnabled: true,
        topOfSplitEnabled: true
      },
      features: {
        treatment_a: {
          conf: {
            treatmentAEnabled: true
          }
        },
        treatment_b: {
          conf: {
            treatmentBEnabled: true,
            topOfSplitEnabled: false
          }
        }
      }
    },
    fruits: {
      conf: {
        fruitsEnabled: true
      },
      features: {
        banana: {
          conf: {
            bananaEnabled: true
          },
          features: {
            yellow_banana: {
              conf: {
                yelloBananaEnabled: true,
                greenBananaEnabled: false
              }
            },
            green_banana: {
              conf: {
                greenBananaEnabled: true,
                yellowBananaEnabled: false
              }
            }
          }
        },
        apple: {
          conf: { 
            appleEnabled: true
          },
          features: {
            green_apple: {
              conf: {
                greenAppleEnabled: true,
                redAppleEnabled: false
              }
            },
            red_apple: {
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

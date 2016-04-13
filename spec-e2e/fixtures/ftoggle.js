module.exports = {
  version: 2,
  name: 'test',
  features: {
    foo: {
      traffic: 1
    },
    bar: {
      traffic: 0
    },
    treatments: {
      exclusiveSplit: 1,
      traffic: 1,
      features: {
        treatment_a: {
          traffic: 0.5
        },
        treatment_b: {
          traffic: 0.5
        }
      }
    },
    fruits: {
      exclusiveSplit: 1,
      traffic: 0,
      features: {
        banana: {
          exclusiveSplit: true,
          traffic: 0.5,
          features: {
            yellow_banana: {
              traffic: 0.5
            },
            green_banana: {
              traffic: 0.5
            }
          }
        },
        apple: {
          exclusiveSplit: true,
          traffic: 0.5,
          features: {
            green_apple: {
              traffic: 0.5
            },
            red_apple: {
              traffic: 0.5
            }
          }
        }
      }
    }
  }
};

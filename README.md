# Breaking reCAPTCHA

## A dissertation project, achieving an overall 80% accuracy

![Traffic Light Image Detection](https://ibb.co/K0H4YGN)

The program can be tuned using the below code to work with a variety of reCAPTCHA scenarios.

```bash
let detectionView = DetectionView(category: .crosswalk,
                                          size: size,
                                          image: image,
                                          depth: 3,
                                          isFullScreenImage: false,
                                          precision: 0)
```

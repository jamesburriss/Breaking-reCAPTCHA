# Breaking reCAPTCHA

## A dissertation project, achieving an overall 80% accuracy

![Traffic Light Image Detection](https://i.ibb.co/HFQw02N/Untitled-2.png)

The program can be tuned using the below code to work with a variety of reCAPTCHA scenarios.

```bash
let detectionView = DetectionView(category: .crosswalk,
                                          size: size,
                                          image: image,
                                          depth: 3,
                                          isFullScreenImage: false,
                                          precision: 0)
```

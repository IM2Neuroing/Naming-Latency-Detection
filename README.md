# Initial Phoneme-based Algorithm for Automatic Naming Latency Detection

Institute for Medical Engineering and Medical Informatics @

![University Logo](Logo/043_FHNW_HLS_EN.png)![University Logo](Logo/044_FHNW_HLS_Weiss_EN.png)

This repository contains the code and sample data for the research paper titled "Can an initial phoneme-based algorithm improve automatic Naming Latency Detection during Picture Naming Tasks? A feasibility study", conducted at University of Applied Sciences and Arts Northwestern Switzerland. Our research aims to enhance the accuracy and efficiency of automatic naming latency detection, a critical component in various language and speech-related applications.

## Contributors

This research and codebase are a result of collaborative efforts from the following contributors:
- [Rickert E.](https://github.com/elirickert) - **Lead researcher**
- Altermatt S. - **Lead researcher**
- Park S.
- Kuntner K.
- Widmer Beierlein S.
- Blechschmidt A.
- Reymond C.
- Degen M.
- Hemm S. - **Project leader**
- [Stawiski M.](https://github.com/stawiskm) - **Code maintenance**

## Abstract

Proposed automatic naming latency (aNL) detection algorithms often differ from manual naming latency detections (mNL) and rely on the initial phoneme (IP). The study aimed to explore the potential of IP-based optimization to enhance aNL detection quality. An algorithm was developed to analyze signal speech envelopes and optimize detection parameters for each IP starting from a reference time.

## Dataset

The dataset used in this research is not publicly available due to privacy concerns. However, we provide a sample dataset (`SampleData.zip`) containing a limited number of samples for demonstration purposes. Researchers can use their datasets by following the provided format.

## Code Overview

`latency_detection.m`: The core implementation of the initial phoneme-based algorithm resides in this script. Showcasing how to use the algorithm with the sample dataset and visualize the results.

## Getting Started

To run the code and produce the results with the sample data, follow these steps:

1. Clone the repository:

```
git clone https://github.com/IM2Neuroing/Naming-Latency-Detection.git
cd Naming-Latency-Detection
```

2. Install the required toolboxes:

```
>> license('inuse')
audio_system_toolbox
matlab
signal_blocks
signal_toolbox
wavelet_toolbox
```
- [Matlab](https://ch.mathworks.com/)
- [Audio Toolbox](https://ch.mathworks.com/products/audio.html)
- [DSP System Toolbox](https://ch.mathworks.com/products/dsp-system.html?)
- [Signal Processing Toolbox](https://ch.mathworks.com/products/signal.html)
- [Wavelet Toolbox](https://ch.mathworks.com/products/wavelet.html)

3. Decompress SampleData.zip

4. Execute the `latency_detection.m` script to see an example of how the algorithm works with the sample data.

## Citation

If you find this work useful and use it in your research, please cite our paper:

```
@article{
  (unpublished)
}
```

For any questions or inquiries about the code, please contact [Stawiski M.](https://github.com/stawiskm).
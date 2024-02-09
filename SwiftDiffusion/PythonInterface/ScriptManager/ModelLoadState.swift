//
//  ModelLoadState.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/9/24.
//

import Foundation

enum ModelLoadState: Equatable {
  case launching
  case done
  case isLoading
  case failed
  case failedOnLaunch
}

// .done:
// Model loaded in 4.6s (load weights from disk: 0.4s, create model: 0.7s, apply weights to model: 2.8s, move model to device: 0.2s, calculate empty prompt: 0.4s).
//
// .isLoading:
// Reusing loaded model DreamShaperXL_v2_Turbo_DpmppSDE.safetensors [4726d3bab1] to load v1-5-pruned-emaonly.safetensors [6ce0161689]
//
// Loading weights [6ce0161689] from /Users/jb/Dev/GitHub/stable-diffusion-webui/models/Stable-diffusion/v1-5-pruned-emaonly.safetensors
//
// .failed:
//
// .failedOnLaunch: // can go to other models, but cant go back to model that failed to load
//
// Startup time: 3.3s (import torch: 0.9s, import gradio: 0.4s, setup paths: 0.3s, other imports: 0.4s, load scripts: 0.3s, initialize extra networks: 0.4s, create ui: 0.2s).
//
// Applying attention optimization: sub-quadratic... done.
// ...
// Stable diffusion model failed to load
//
// Applying attention optimization: sub-quadratic... done.

// BIG TELL:
// TypeError: Cannot convert a MPS Tensor to float64 dtype as the MPS framework doesn't support float64. Please use float32 instead.

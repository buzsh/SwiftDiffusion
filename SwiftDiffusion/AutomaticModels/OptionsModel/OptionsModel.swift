//
//  OptionsModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import Foundation

extension Constants.API.Endpoint {
  struct Options {
    static let get = "/sdapi/v1/options"
    //static let postRefresh: String = "/sdapi/v1/options"
  }
}

extension OptionsModel: EndpointRepresentable {
  static var fetchEndpoint: String {
    Constants.API.Endpoint.Checkpoints.get
  }
  
  static var refreshEndpoint: String? {
    nil
  }
}

struct OptionsModel: Decodable {
  let samplesSave: Bool
  let samplesFormat: String
  let sdModelCheckpoint: String
  enum CodingKeys: String, CodingKey {
    case samplesSave = "samples_save"
    case samplesFormat = "samples_format"
    case sdModelCheckpoint = "sd_model_checkpoint"
  }
}

/*
struct OptionsModel: Identifiable, Decodable {
  var id = UUID()
  let samplesSave: Bool?
  let samplesFormat: String?
  let samplesFilenamePattern: String?
  let saveImagesAddNumber: Bool?
  let saveImagesReplaceAction: String?
  let gridSave: Bool?
  let gridFormat: String?
  let gridExtendedFilename: Bool?
  let gridOnlyIfMultiple: Bool?
  let gridPreventEmptySpots: Bool?
  let gridZipFilenamePattern: String?
  let nRows: Int?
  let font: String?
  let gridTextActiveColor: String?
  let gridTextInactiveColor: String?
  let gridBackgroundColor: String?
  let saveImagesBeforeFaceRestoration: Bool?
  let saveImagesBeforeHighresFix: Bool?
  let saveImagesBeforeColorCorrection: Bool?
  let saveMask: Bool?
  let saveMaskComposite: Bool?
  let jpegQuality: Int?
  let webpLossless: Bool?
  let exportFor4chan: Bool?
  let imgDownscaleThreshold: Int?
  let targetSideLength: Int?
  let imgMaxSizeMp: Int?
  let useOriginalNameBatch: Bool?
  let useUpscalerNameAsSuffix: Bool?
  let saveSelectedOnly: Bool?
  let saveInitImg: Bool?
  let tempDir: String?
  let cleanTempDirAtStart: Bool?
  let saveIncompleteImages: Bool?
  let notificationAudio: Bool?
  let notificationVolume: Int?
  let outdirSamples: String?
  let outdirTxt2imgSamples: String?
  let outdirImg2imgSamples: String?
  let outdirExtrasSamples: String?
  let outdirGrids: String?
  let outdirTxt2imgGrids: String?
  let outdirImg2imgGrids: String?
  let outdirSave: String?
  let outdirInitImages: String?
  let saveToDirs: Bool?
  let gridSaveToDirs: Bool?
  let useSaveToDirsForUi: Bool?
  let directoriesFilenamePattern: String?
  let directoriesMaxPromptWords: Int?
  let esrganTile: Int?
  let esrganTileOverlap: Int?
  let realesrganEnabledModels: [String]?
  let upscalerForImg2img: String?
  let faceRestoration: Bool?
  let faceRestorationModel: String?
  let codeFormerWeight: Double?
  let faceRestorationUnload: Bool?
  let autoLaunchBrowser: String?
  let enableConsolePrompts: Bool?
  let showWarnings: Bool?
  let showGradioDeprecationWarnings: Bool?
  let memmonPollRate: Int?
  let samplesLogStdout: Bool?
  let multipleTqdm: Bool?
  let printHypernetExtra: Bool?
  let listHiddenFiles: Bool?
  let disableMmapLoadSafetensors: Bool?
  let hideLdmPrints: Bool?
  let dumpStacksOnSignal: Bool?
  let apiEnableRequests: Bool?
  let apiForbidLocalRequests: Bool?
  let apiUseragent: String?
  let unloadModelsWhenTraining: Bool?
  let pinMemory: Bool?
  let saveOptimizerState: Bool?
  let saveTrainingSettingsToTxt: Bool?
  let datasetFilenameWordRegex: String?
  let datasetFilenameJoinString: String?
  let trainingImageRepeatsPerEpoch: Int?
  let trainingWriteCsvEvery: Int?
  let trainingXattentionOptimizations: Bool?
  let trainingEnableTensorboard: Bool?
  let trainingTensorboardSaveImages: Bool?
  let trainingTensorboardFlushEvery: Int?
  let sdModelCheckpoint: String?
  
  enum CodingKeys: String, CodingKey {
    case samplesSave = "samples_save"
    case samplesFormat = "samples_format"
    case samplesFilenamePattern = "samples_filename_pattern"
    case saveImagesAddNumber = "save_images_add_number"
    case saveImagesReplaceAction = "save_images_replace_action"
    case gridSave = "grid_save"
    case gridFormat = "grid_format"
    case gridExtendedFilename = "grid_extended_filename"
    case gridOnlyIfMultiple = "grid_only_if_multiple"
    case gridPreventEmptySpots = "grid_prevent_empty_spots"
    case gridZipFilenamePattern = "grid_zip_filename_pattern"
    case nRows = "n_rows"
    case font
    case gridTextActiveColor = "grid_text_active_color"
    case gridTextInactiveColor = "grid_text_inactive_color"
    case gridBackgroundColor = "grid_background_color"
    case saveImagesBeforeFaceRestoration = "save_images_before_face_restoration"
    case saveImagesBeforeHighresFix = "save_images_before_highres_fix"
    case saveImagesBeforeColorCorrection = "save_images_before_color_correction"
    case saveMask = "save_mask"
    case saveMaskComposite = "save_mask_composite"
    case jpegQuality = "jpeg_quality"
    case webpLossless = "webp_lossless"
    case exportFor4chan = "export_for_4chan"
    case imgDownscaleThreshold = "img_downscale_threshold"
    case targetSideLength = "target_side_length"
    case imgMaxSizeMp = "img_max_size_mp"
    case useOriginalNameBatch = "use_original_name_batch"
    case useUpscalerNameAsSuffix = "use_upscaler_name_as_suffix"
    case saveSelectedOnly = "save_selected_only"
    case saveInitImg = "save_init_img"
    case tempDir = "temp_dir"
    case cleanTempDirAtStart = "clean_temp_dir_at_start"
    case saveIncompleteImages = "save_incomplete_images"
    case notificationAudio = "notification_audio"
    case notificationVolume = "notification_volume"
    case outdirSamples = "outdir_samples"
    case outdirTxt2imgSamples = "outdir_txt2img_samples"
    case outdirImg2imgSamples = "outdir_img2img_samples"
    case outdirExtrasSamples = "outdir_extras_samples"
    case outdirGrids = "outdir_grids"
    case outdirTxt2imgGrids = "outdir_txt2img_grids"
    case outdirImg2imgGrids = "outdir_img2img_grids"
    case outdirSave = "outdir_save"
    case outdirInitImages = "outdir_init_images"
    case saveToDirs = "save_to_dirs"
    case gridSaveToDirs = "grid_save_to_dirs"
    case useSaveToDirsForUi = "use_save_to_dirs_for_ui"
    case directoriesFilenamePattern = "directories_filename_pattern"
    case directoriesMaxPromptWords = "directories_max_prompt_words"
    case esrganTile = "ESRGAN_tile"
    case esrganTileOverlap = "ESRGAN_tile_overlap"
    case realesrganEnabledModels = "realesrgan_enabled_models"
    case upscalerForImg2img = "upscaler_for_img2img"
    case faceRestoration = "face_restoration"
    case faceRestorationModel = "face_restoration_model"
    case codeFormerWeight = "code_former_weight"
    case faceRestorationUnload = "face_restoration_unload"
    case autoLaunchBrowser = "auto_launch_browser"
    case enableConsolePrompts = "enable_console_prompts"
    case showWarnings = "show_warnings"
    case showGradioDeprecationWarnings = "show_gradio_deprecation_warnings"
    case memmonPollRate = "memmon_poll_rate"
    case samplesLogStdout = "samples_log_stdout"
    case multipleTqdm = "multiple_tqdm"
    case printHypernetExtra = "print_hypernet_extra"
    case listHiddenFiles = "list_hidden_files"
    case disableMmapLoadSafetensors = "disable_mmap_load_safetensors"
    case hideLdmPrints = "hide_ldm_prints"
    case dumpStacksOnSignal = "dump_stacks_on_signal"
    case apiEnableRequests = "api_enable_requests"
    case apiForbidLocalRequests = "api_forbid_local_requests"
    case apiUseragent = "api_useragent"
    case unloadModelsWhenTraining = "unload_models_when_training"
    case pinMemory = "pin_memory"
    case saveOptimizerState = "save_optimizer_state"
    case saveTrainingSettingsToTxt = "save_training_settings_to_txt"
    case datasetFilenameWordRegex = "dataset_filename_word_regex"
    case datasetFilenameJoinString = "dataset_filename_join_string"
    case trainingImageRepeatsPerEpoch = "training_image_repeats_per_epoch"
    case trainingWriteCsvEvery = "training_write_csv_every"
    case trainingXattentionOptimizations = "training_xattention_optimizations"
    case trainingEnableTensorboard = "training_enable_tensorboard"
    case trainingTensorboardSaveImages = "training_tensorboard_save_images"
    case trainingTensorboardFlushEvery = "training_tensorboard_flush_every"
    case sdModelCheckpoint = "sd_model_checkpoint"
  }
}
*/

/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { objectDetection, visionBase } from '@kit.CoreVisionKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { LengthMetrics } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  private imageSource: image.ImageSource | undefined = undefined;
  @State chooseImage: PixelMap | undefined = undefined
  @State dataValues: string = ''

  build() {
    Column() {
      Row() {
        Image(this.chooseImage)
          .objectFit(ImageFit.Contain)
      }
      .height('50%')
      .width('90%')
      .margin({
        bottom: LengthMetrics.vp(12)
      })

      Row() {
        Scroll() {
          Text(this.dataValues)
            .copyOption(CopyOptions.LocalDevice)
            .margin(10)
            .width('90%')
        }
        .margin(10)
        .width('90%')
        .backgroundColor('rgba(0, 0, 0, 0.05)')
        .borderRadius(16)
        .height('100%') // Sets the height of the Scroll component.
      }
      .height('30%')
      .margin({
        bottom: LengthMetrics.vp(12)
      })

      Button('Select image')
        .onClick(() => {
          // Pull up the gallery.
          this.selectImage()
        })
        .width('80%')
        .margin({
          bottom: LengthMetrics.vp(12)
        })

      Button('Start multi-object detection')
        .fontColor(Color.White)
        .alignSelf(ItemAlign.Center)
        .width('80%')
        .margin({
          bottom: LengthMetrics.vp(16)
        })
        .onClick(async () => {
          if(!this.chooseImage) {
            hilog.error(0x0000, 'objectDetectSample', `Failed to choose image. chooseImage: ${this.chooseImage}`);
            return;
          }
          let request: visionBase.Request = {
            inputData: { pixelMap: this.chooseImage }
          };
          try {
            let data: objectDetection.ObjectDetectionResponse =
              await (await objectDetection.ObjectDetector.create()).process(request);
            let objectJson = JSON.stringify(data);
            hilog.info(0x0000, 'objectDetectSample', `Succeeded in object detect: ${objectJson}`);
            this.dataValues = objectJson;
          } catch (error) {
            hilog.error(0x0000, 'objectDetectSample', "Failed in object detect: " + JSON.stringify(error));
          }
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
  }

  private async selectImage() {
    let uri = await this.openPhoto()
    if (uri === undefined) {
      hilog.error(0x0000, 'objectDetectSample', "Failed to defined uri.");
    }
    this.loadImage(uri)
  }

  private openPhoto(): Promise<string> {
    return new Promise<string>((resolve, reject) => {
      let photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      photoPicker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE, maxSelectNumber: 1
      }).then(res => {
        resolve(res.photoUris[0])
      }).catch((err: BusinessError) => {
        hilog.error(0x0000, 'objectDetectSample', `Failed to get photo image uri. code: ${err.code}，message: ${err.message}`);
        reject('')
      })
    })
  }

  private loadImage(name: string) {
    setTimeout(async () => {
      try {
        let fileSource = await fileIo.open(name, fileIo.OpenMode.READ_ONLY);
        this.imageSource = image.createImageSource(fileSource.fd);
        this.chooseImage = await this.imageSource.createPixelMap();
      } catch (error) {
        hilog.error(0x0000, 'objectDetectSample', "fileIo.open error: " + JSON.stringify(error));
      }
    }, 100)
  }
}

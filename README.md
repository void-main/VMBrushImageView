# VMBrushImageView
Brush foreground and background on a NSImageView.

## Demo
`VMBrushImageView` is intended to work as a view component for interactive image segmentation, which takes advantage of user scribbles.

![Brush Demo](./demo_brush.gif)

`VMBrushImageView` provides 3 types of brushes, namely: `Foreground`, `Background` and `Eraser`.

## Setup
To setup for your project, copy the classes from `VMBrushImageView` folder to your project and you are all set.

<b>Note:</b>you may have noticed the `NSImage+BitmapRep` category, it is a quite common helper class. So if you happen to have one in your project, feel free to get rid of my implementation. Or, even better, if you would like to share with me your implementation, please send a pull request.
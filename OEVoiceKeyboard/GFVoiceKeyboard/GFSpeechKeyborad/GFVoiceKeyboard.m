//
//  GFVoiceKeyboard.m
//  gf_testVoice
//
//  Created by gaof on 2017/4/7.
//  Copyright © 2017年 gaof. All rights reserved.
//

#import "GFVoiceKeyboard.h"
#import "ISRDataHelper.h"
#import "iflyMSC/iflyMSC.h"
#import "IATConfig.h"
#import "YSCVoiceWaveView.h"
#define ScreenWidth     [UIScreen mainScreen].bounds.size.width
#define ScreenHeight    [UIScreen mainScreen].bounds.size.height

CGFloat const keyboardHeight = 260;

@interface GFVoiceKeyboard()<IFlySpeechRecognizerDelegate,IFlyPcmRecorderDelegate,UITextViewDelegate>

@property (nonatomic,strong) YSCVoiceWaveView *voiceWaveView;
@property (nonatomic, strong) IFlySpeechRecognizer *iFlySpeechRecognizer;//不带界面的识别对象
@property (nonatomic, copy)void (^resultBlock)(NSString *);
@property (nonatomic,assign) BOOL isStreamRec;//是否是音频流识别
@property (nonatomic,assign) BOOL isBeginOfSpeech;//是否返回BeginOfSpeech回调
@property (nonatomic, assign) BOOL isCanceled;
@property (nonatomic, strong) NSString * result;
@property (nonatomic,strong) IFlyPcmRecorder *pcmRecorder;//录音器，用于音频流识别的数据传入
@property (nonatomic, strong) NSTimer *updateVolumeTimer;
@property (nonatomic,copy) void(^dismissBlock)();

@end
@implementation GFVoiceKeyboard{
    
    
    UIButton *_startBtn;
    UIButton *_cencelBtn;
    UIButton *_doBtn;
    
    float _volume;
    
    UIView *_contentView;
    
    UILabel *_lab_hint;

    UITextView *_textView;
    
}

-(instancetype)init {
    self  = [super initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height-keyboardHeight, [UIScreen mainScreen].bounds.size.width, keyboardHeight)];
    if (self) {
        [self setupSubViews];
    }
    return self;

}
- (void)setupSubViews {
    NSLog(@"%@",NSStringFromCGRect(self.frame));
    _contentView = [[UIView alloc] initWithFrame:self.bounds];
    _contentView.backgroundColor = [UIColor whiteColor];
    [self addSubview:_contentView];
    _textView = [[UITextView alloc] initWithFrame:CGRectMake(15, 15, [UIScreen mainScreen].bounds.size.width-30, keyboardHeight-150)];
    _textView.returnKeyType = UIReturnKeyDone;
    _textView.delegate = self;
    _textView.font = [UIFont systemFontOfSize:15];
    _textView.userInteractionEnabled = NO;
    [_contentView addSubview:_textView];
    
    _startBtn = [[UIButton alloc] init];
    [_startBtn setBackgroundImage:[UIImage imageNamed:@"icon_xnd_spk"] forState:UIControlStateNormal];
    [_contentView addSubview:_startBtn];
    [_startBtn addTarget:self action:@selector(startClick) forControlEvents:UIControlEventTouchDown];
    [_startBtn addTarget:self action:@selector(stopBtnHandler) forControlEvents:UIControlEventTouchUpInside];
    
    _cencelBtn = [[UIButton alloc] init];
    [_cencelBtn addTarget:self action:@selector(placeholderClick) forControlEvents:UIControlEventTouchUpInside];
    [_cencelBtn setTitle:@"取消" forState:UIControlStateNormal];
    _cencelBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [_cencelBtn setTitleColor:[UIColor colorWithRed:0.18 green:0.22 blue:0.26 alpha:1.00] forState:UIControlStateNormal];
    [_contentView addSubview:_cencelBtn];
    
    _doBtn = [[UIButton alloc] init];
    [_doBtn addTarget:self action:@selector(sendClick) forControlEvents:UIControlEventTouchUpInside];
    [_doBtn setTitle:@"确认" forState:UIControlStateNormal];
    [_doBtn setTitleColor:[UIColor colorWithRed:0.00 green:0.69 blue:0.40 alpha:1.00] forState:UIControlStateNormal];
    _doBtn.hidden = YES;
    _doBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [_contentView addSubview:_doBtn];
    
    _lab_hint = [[UILabel alloc] init];
    _lab_hint.text = @"按住说话";
    _lab_hint.font = [UIFont systemFontOfSize:13];
    _lab_hint.textColor = [UIColor colorWithRed:0.18 green:0.22 blue:0.26 alpha:1.00];
    _lab_hint.textAlignment = NSTextAlignmentCenter;
    [_contentView addSubview:_lab_hint];

}

-(void)layoutSubviews {
    [super layoutSubviews];
    _startBtn.frame = CGRectMake(0, 0, 80, 80);
    _startBtn.center = CGPointMake(self.center.x, keyboardHeight-50);
    _cencelBtn.frame = CGRectMake(0, 0, 44, 44);
    _cencelBtn.center = CGPointMake(_startBtn.center.x*0.5-15, _startBtn.center.y);
    
    _doBtn.frame = CGRectMake(0, 0, 44, 44);
    _doBtn.center = CGPointMake(_startBtn.center.x+_startBtn.center.x*0.5+15, _startBtn.center.y);
    
    _lab_hint.frame = CGRectMake(0,CGRectGetMinY(_startBtn.frame)-30 , ScreenWidth, 30);
    
}


#pragma mark - Action
//发送
- (void)sendClick {
    if (self.resultBlock) {
        self.resultBlock(_textView.text);
    }
    if ([self.delegate respondsToSelector:@selector(voiceKeyboardDidRecognitionResult:)]) {
        [self.delegate voiceKeyboardDidRecognitionResult:_textView.text];
    }
    
    [self placeholderClick];
    _textView.text = nil;
}

//取消
- (void)placeholderClick {
    [self dismiss];
    //取消听写
    [self cancelBtnHandler];
    _iFlySpeechRecognizer = nil;
    
}

//show
- (void)keyboardRecognition:(void (^)(NSString *result))block {
    if (block){
        self.resultBlock = block;
    }
}
- (void)keyboardDismiss:(void(^)())block {
    if (block) {
        self.dismissBlock = block;
    }
}
//dismiss

- (void)dismiss {
    if (self.dismissBlock) {
        self.dismissBlock();
    }
    if ([self.delegate respondsToSelector:@selector(voiceKeyboardDidDismiss)]) {
        [self.delegate voiceKeyboardDidDismiss];
    }
}

//开始录音
- (void)startClick {
    _lab_hint.text = @"";
    [self.voiceWaveView showInParentView:_contentView];
    [self.voiceWaveView startVoiceWave];
    [[NSRunLoop currentRunLoop] addTimer:self.updateVolumeTimer forMode:NSRunLoopCommonModes];
    
    
    NSLog(@"%s[IN]",__func__);
    
    [_textView resignFirstResponder];
    self.isCanceled = NO;
    self.isStreamRec = NO;
    
    if(_iFlySpeechRecognizer == nil)
    {
        [self initRecognizer];
    }
    
    [_iFlySpeechRecognizer cancel];
    
    //设置音频来源为麦克风
    [_iFlySpeechRecognizer setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];

    //设置听写结果格式为json
    [_iFlySpeechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
    
    //保存录音文件，保存在sdk工作路径中，如未设置工作路径，则默认保存在library/cache下
    [_iFlySpeechRecognizer setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
    
    [_iFlySpeechRecognizer setDelegate:self];
    
    BOOL ret = [_iFlySpeechRecognizer startListening];
    
    if (ret) {
//        [_audioStreamBtn setEnabled:NO];
//        [_upWordListBtn setEnabled:NO];
//        [_upContactBtn setEnabled:NO];
        
    }else{
//        [_popUpView showText: @"启动识别服务失败，请稍后重试"];//可能是上次请求未结束，暂不支持多路并发
    }
    
}
/**
 取消听写
 *****/
- (void)cancelBtnHandler{
    
    NSLog(@"%s",__func__);
    
    if(self.isStreamRec && !self.isBeginOfSpeech){
        NSLog(@"%s,停止录音",__func__);
        [_pcmRecorder stop];
    }
    self.isCanceled = YES;
    
    [_iFlySpeechRecognizer cancel];
    
    
    
}

/**
 停止录音
 *****/
- (void)stopBtnHandler {
    
    [self.voiceWaveView stopVoiceWaveWithShowLoadingViewCallback:^{
        [self.updateVolumeTimer invalidate];
        _updateVolumeTimer = nil;
    }];
    NSLog(@"%s",__func__);
    
    if(self.isStreamRec && !self.isBeginOfSpeech){
        NSLog(@"%s,停止录音",__func__);
        [_pcmRecorder stop];
    }
    [_iFlySpeechRecognizer stopListening];
}


#pragma mark - iflyMsc
/**
 设置识别参数
 ****/
-(void)initRecognizer
{
    NSLog(@"%s",__func__);
    
        //单例模式，无UI的实例
        if (_iFlySpeechRecognizer == nil) {
            _iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
            
            [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
            
            //设置听写模式
            [_iFlySpeechRecognizer setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
        }
        _iFlySpeechRecognizer.delegate = self;
        
        if (_iFlySpeechRecognizer != nil) {
            IATConfig *instance = [IATConfig sharedInstance];
            //设置最长录音时间
            [_iFlySpeechRecognizer setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
            //设置后端点
            [_iFlySpeechRecognizer setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
            //设置前端点
            [_iFlySpeechRecognizer setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
            //网络等待时间
            [_iFlySpeechRecognizer setParameter:@"20000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
            
            //设置采样率，推荐使用16K
            [_iFlySpeechRecognizer setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
            
            if ([instance.language isEqualToString:[IATConfig chinese]]) {
                //设置语言
                [_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
                //设置方言
                [_iFlySpeechRecognizer setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
            }else if ([instance.language isEqualToString:[IATConfig english]]) {
                [_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
            }
            [_iFlySpeechRecognizer setParameter:@"0" forKey:@"asr_ptt"];
        }
        
        //初始化录音器
        if (_pcmRecorder == nil)
        {
            _pcmRecorder = [IFlyPcmRecorder sharedInstance];
        }
        
        _pcmRecorder.delegate = self;
        
        [_pcmRecorder setSample:[IATConfig sharedInstance].sampleRate];
        
        [_pcmRecorder setSaveAudioPath:nil];    //不保存录音文件
    
}


/**
 音量回调函数
 volume 0－30
 ****/
- (void) onVolumeChanged: (int)volume
{
    if (self.isCanceled) {
        
        return;
    }
    
    _volume = volume/30.0;
}



/**
 开始识别回调
 ****/
- (void) onBeginOfSpeech
{
    NSLog(@"onBeginOfSpeech");
    
    if (self.isStreamRec == NO)
    {
        self.isBeginOfSpeech = YES;
        NSLog(@"正在录音");
    }
}

/**
 停止录音回调
 ****/
- (void) onEndOfSpeech
{
    NSLog(@"onEndOfSpeech");
    
    [_pcmRecorder stop];
    NSLog(@"停止录音");
    
}



/**
 听写结束回调（注：无论听写是否正确都会回调）
 error.errorCode =
 0     听写正确
 other 听写出错
 ****/
- (void) onError:(IFlySpeechError *) error
{

    
    NSLog(@"%s",__func__);
    
    if ([IATConfig sharedInstance].haveView == NO ) {
        
        //        if (self.isStreamRec) {
        //            //当音频流识别服务和录音器已打开但未写入音频数据时stop，只会调用onError不会调用onEndOfSpeech，导致录音器未关闭
        //            [_pcmRecorder stop];
        //            self.isStreamRec = NO;
        //            NSLog(@"error录音停止");
        //        }
        
        NSString *text ;
        
        if (self.isCanceled) {
            text = @"识别取消";
            
        } else if (error.errorCode == 0 ) {
            if (_result.length == 0) {
                text = @"无识别结果";
            }else {
                text = @"识别成功";
                //清空识别结果
                _result = nil;
                _doBtn.hidden = NO;
            }
        }else {
            text = [NSString stringWithFormat:@"发生错误：%d %@", error.errorCode,error.errorDesc];
            NSLog(@"%@",text);
        }
        NSLog(@"%@",text);
        
        
    }else {
        NSLog(@"识别结束");
        NSLog(@"errorCode:%d",[error errorCode]);
    }
//    
//    [_startRecBtn setEnabled:YES];
//    [_audioStreamBtn setEnabled:YES];
//    [_upWordListBtn setEnabled:YES];
//    [_upContactBtn setEnabled:YES];
    
}

/**
 无界面，听写结果回调
 results：听写结果
 isLast：表示最后一次
 ****/
- (void) onResults:(NSArray *) results isLast:(BOOL)isLast
{
    
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = results[0];
    for (NSString *key in dic) {
        [resultString appendFormat:@"%@",key];
    }
    _result =[NSString stringWithFormat:@"%@",resultString];
    NSString * resultFromJson =  [ISRDataHelper stringFromJson:resultString];
//    _textView.text = [NSString stringWithFormat:@"%@%@", _textView.text,resultFromJson];
    
    if (isLast){
        NSLog(@"听写结果(json)：%@测试",  self.result);
    }
    NSLog(@"_result=%@",_result);
    
    _textView.text = [NSString stringWithFormat:@"%@%@",_textView.text,resultFromJson];
    _lab_hint.text = @"按住说话";

}




#pragma mark - IFlyPcmRecorderDelegate

- (void) onIFlyRecorderBuffer: (const void *)buffer bufferSize:(int)size
{
    NSData *audioBuffer = [NSData dataWithBytes:buffer length:size];
    
    int ret = [self.iFlySpeechRecognizer writeAudio:audioBuffer];
    if (!ret)
    {
        [self.iFlySpeechRecognizer stopListening];
        
    }
}

- (void) onIFlyRecorderError:(IFlyPcmRecorder*)recoder theError:(int) error
{
    
}



- (NSTimer *)updateVolumeTimer
{
    if (!_updateVolumeTimer) {
        self.updateVolumeTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updateVolume:) userInfo:nil repeats:YES];
    }
    
    return _updateVolumeTimer;
}
- (void)updateVolume:(NSTimer *)timer
{
    
    [self.voiceWaveView changeVolume:_volume];
    
}


#pragma mark - textViewDelegate
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [_textView endEditing:YES];
        return NO;
    }
    return YES;
}
-(void)textViewDidBeginEditing:(UITextView *)textView {
    if ([self.delegate respondsToSelector:@selector(voiceKeyboardTextViewDidBeginEditing:)]) {
        [self.delegate voiceKeyboardTextViewDidBeginEditing:textView];
    }
}

#pragma -getter
- (YSCVoiceWaveView *)voiceWaveView
{
    if (!_voiceWaveView) {
        _voiceWaveView = [[YSCVoiceWaveView alloc] init];
    }
    
    return _voiceWaveView;
}

//============单例================
//static id _instance;
//+(instancetype)allocWithZone:(struct _NSZone *)zone {
//    if (_instance == nil){
//        _instance = [super allocWithZone:zone];
//    }
//    return _instance;
//}
//
//
//- (instancetype) init {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        _instance = [super initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height-keyboardHeight, [UIScreen mainScreen].bounds.size.width, keyboardHeight)];
//        [self setupSubViews];
//    });
//    return _instance;
//}
//
//+ (instancetype)copyWithZone:(struct _NSZone *)zone{
//    return _instance;
//}
//+(instancetype)mutableCopyWithZone:(struct _NSZone *)zone{
//    return _instance;
//}
//
//
//+ (instancetype)share {
//    return [[self alloc] init];
//}


@end

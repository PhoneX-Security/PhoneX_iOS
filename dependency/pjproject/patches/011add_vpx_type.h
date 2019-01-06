Index: pjproject/sources/pjmedia/include/pjmedia-codec/types.h
===================================================================
--- pjproject.orig/sources/pjmedia/include/pjmedia-codec/types.h
+++ pjproject/sources/pjmedia/include/pjmedia-codec/types.h
@@ -116,6 +116,7 @@ enum pjmedia_video_pt
      PJMEDIA_RTP_PT_H264_RSV2,
      PJMEDIA_RTP_PT_H264_RSV3,
      PJMEDIA_RTP_PT_H264_RSV4,
+     PJMEDIA_RTP_PT_VP8,
 
      /* Caution!
       * Ensure the value of the last pt above is <= 127.

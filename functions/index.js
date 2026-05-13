const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { RtcTokenBuilder, RtcRole } = require("agora-token");

// KHỞI TẠO LÀ BẮT BUỘC ĐỂ TRÁNH TREO APP (XOAY XOAY)
admin.initializeApp();

const APP_ID = "60b853ab652045a6af74da86d5e9e304";
const APP_CERTIFICATE = "4edf7962443d4a0384dae6f56d4a6d6b";
const TOKEN_EXPIRY_SECONDS = 3600; // 1 giờ

exports.generateAgoraToken = functions.https.onCall((data, context) => {
  // 1. Kiểm tra xác thực (Người dùng phải đăng nhập)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Bạn cần đăng nhập để thực hiện chức năng này."
    );
  }

  // 2. Lấy tên kênh từ dữ liệu gửi lên
  const channelName = data.channelName;
  if (!channelName) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Thiếu tên kênh (channelName)."
    );
  }

  const uid = 0; // 0 để Agora tự động cấp UID
  const role = RtcRole.PUBLISHER;
  const expireTime = Math.floor(Date.now() / 1000) + TOKEN_EXPIRY_SECONDS;

  try {
    // 3. Tạo Token trong khối try-catch để an toàn, tránh treo app khi có lỗi ngầm
    const token = RtcTokenBuilder.buildTokenWithUid(
      APP_ID,
      APP_CERTIFICATE,
      channelName,
      uid,
      role,
      expireTime,
      expireTime
    );

    // Trả kết quả về cho App Flutter
    return { token };
  } catch (error) {
    console.error("Token Generation Error:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Lỗi server trong quá trình tạo mã bảo mật cuộc gọi."
    );
  }
});

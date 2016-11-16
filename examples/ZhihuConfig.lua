return {
    IsUseConcurrent = true,     --是否开启并发(如果为true，才使用 MaxConcurrentPicNum)-- 经过测试,不开启它更安全和稳定
    MaxConcurrentPicNum = 5,   --最多同时开启的图片请求

    saveDir = "ZhihuPic",   --图片的存放目录
    querys = {
        {
            dirname = "meitui",
            q = "美腿",       -- 搜索的问题关键字
            startOffset = 0,      -- 起始偏移
            count = 5,     --翻页次数
        },
        {
            dirname = "maidi",
            q = "麦迪",       -- 搜索的问题关键字
            startOffset = 0,      -- 起始偏移
            count = 5,     --翻页次数
        },
    },
}
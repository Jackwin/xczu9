#pragma once
/* dma transmit from or to file interface
 */

#include <string>
#include <memory>

namespace bsd {

class FileIntfImpl;

enum RET_VAL{
    RET_SUCCESS = 0,
    RET_INIT_ALREADY,
    RET_NOT_INIT,
    RET_FILE_NOEXIST,
    RET_FILE_EXIST,
    RET_FILE_READ_FAILED,
    RET_FILE_WRITE_FAILED,
    RET_PATH_READ_FAILED,
    RET_BUFFER_INSUF,
    RET_DEVICE_ERR,
    RET_SEND_ERR,
    RET_RECV_ERR,
    RET_NONE
};

class FileIntf {
public:
/* get_instance(): 获取单实例
 */
    static FileIntf& get_instance();

/* init(): 根据json配置文件进行设备初始化
 * conf_json: json配置文件路径，为空使用内部默认设置
 */

    RET_VAL init(const std::string conf_json = "");

/* send_file(): 读取数据文件，发送到设备
 * file_path: 待发送数据文件路径
 * return： 返回RET_VAL
 */

    RET_VAL send_file(const std::string file_path);

/* send_path(): 将指定路径下所有文件，发送到设备
 * path: 指定的路径
 * return： 返回RET_VAL
 */
    RET_VAL send_path(const std::string path);

/* recv_file(): 从设备接收数据，并写入指定的文件
 * file_path: 待写入数据文件路径
 * return： 返回RET_VAL
 */    
    RET_VAL recv_file(const std::string file_path);

/* recv_path(): 从设备接收数据，并按文件写入指定的路径下面
 * path: 待写入数据路径
 * format: 文件命名格式，如file_02d.data 表示file_00.data ~ file_99.data
 * return： 返回RET_VAL
 */        
    RET_VAL recv_path(const std::string path, const std::string format = "");

private:
    FileIntf();
    ~FileIntf();
    std::shared_ptr<bsd::FileIntfImpl> _pimpl;
};

}//namespace bsd
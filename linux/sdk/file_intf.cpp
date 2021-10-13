#include <stdio.h>
#include <stdlib.h>
#include <fstream>
#include <fcntl.h>
#include <dirent.h>
#include <cstring>
#include <sys/ioctl.h>
#include <sys/mman.h>

#include "file_intf.hpp"
#include "fbga_com.h"

#ifdef DEBUG
#define dbg(fmt, args...) \
        do { printf("[%s():%d]:\t", __func__, __LINE__); printf(fmt, ##args); } while (0)
#else
#define dbg(fmt, args...)
#endif

namespace bsd {

struct DevDesc {
    int fd;
    void* map_data;
    uint64_t map_len;
};

class FileIntfImpl {
public:
    FileIntfImpl() {
        _devd.fd = -1;
        _devd.map_data = nullptr;
        _devd.map_len = 128 * 1024 * 1024;  //128MB
    }

    ~FileIntfImpl() {}

    RET_VAL init(const std::string conf_json = "") {
        if (_binited) {
            dbg("already inited\n");
            return RET_INIT_ALREADY;
        }
        if (0 != open_and_map()) {
            dbg("open_and_map device failed\n");
            return RET_DEVICE_ERR;
        }
        _binited = true;
        return RET_SUCCESS;
    }

    RET_VAL send_file(const std::string file_path) {
        if (!_binited) {
            dbg("device not init.\n");
            return RET_NOT_INIT;
        }
        std::ifstream infile(file_path, std::iostream::binary);
        if(!infile) {
            dbg("file open failed\n");
            return RET_FILE_READ_FAILED;
        }
        infile.seekg(0, infile.end);
        uint64_t len = infile.tellg();
        infile.seekg(0, infile.beg);
        if (len > _devd.map_len) {
            dbg("file length bigger then buffer.\n");
            return RET_BUFFER_INSUF;
        }
        infile.read(static_cast<char*>(_devd.map_data), len);
        struct data_config_t dma_conf;
        dma_conf.addr_off = 0;
        dma_conf.data_len = len;
        if ((0 != ioctl(_devd.fd, IOCMD_DMA_CONFIGRX, &dma_conf))
            || (!(dma_conf.status & TRANS_STAT_FILE_DONE))) {
            dbg("dma tx faild\n");
            return RET_SEND_ERR;
        }
        return RET_SUCCESS;
    }

    RET_VAL send_path(const std::string path) {
        if (!_binited) {
            dbg("device not init.\n");
            return RET_NOT_INIT;
        }

        struct dirent* one_ent = nullptr;
        DIR* dir = opendir(path.c_str());
        if (nullptr == dir) {
            dbg("couldn't open path: %s\n", path);
            return RET_PATH_READ_FAILED;
        }
        while((one_ent = readdir(dir)) != nullptr) {
            if (0 == std::strcmp(one_ent->d_name, ".") || 0 == std::strcmp(one_ent->d_name, "..")) {
                continue;
            }
            if (RET_SUCCESS != send_file(one_ent->d_name)) {
                dbg("send file: %s failed\n", one_ent->d_name);
                return RET_SEND_ERR;
            }
        }
        return RET_SUCCESS;
    }

    RET_VAL recv_file(const std::string file_path) {
        if (!_binited) {
            dbg("device not init.\n");
            return RET_NOT_INIT;
        }
        std::ofstream outfile(file_path, std::iostream::binary);
        if (!outfile) {
            dbg("file open failed\n");
            return RET_FILE_WRITE_FAILED;
        }

        struct data_config_t dc;
        dc.addr_off = 0;
        uint32_t dlen = ioctl(_devd.fd, IOCMD_DMA_CONFIGRX, &dc);
        if (dlen < 0) {
            dbg("dma rx faild, return:%d,stat:0x%x,\n", dlen, dc.status);
            return RET_RECV_ERR;
        }
        outfile.write(static_cast<char*>(_devd.map_data), dlen);

        return RET_SUCCESS;
    }

    RET_VAL recv_path(const std::string path, const std::string format = "") {
        if (!_binited) {
            dbg("device not init.\n");
            return RET_NOT_INIT;
        }

        struct dirent* one_ent = nullptr;
        DIR* dir = opendir(path.c_str());
        if (nullptr == dir) {
            dbg("couldn't open path: %s\n", path);
            return RET_PATH_READ_FAILED;
        }
        
        char name[256];
        if (format.empty()) {
            snprintf(name, 256, "data");
        }
        return RET_SUCCESS;
    }

private:
    bool _binited {false};
    char* _strdevfile {"/dev/fbga_drv"};
    DevDesc _devd;

    int open_and_map() {
        _devd.fd = open(_strdevfile, O_RDWR); 
        if (_devd.fd <= 0) {
            perror("open failed!");
            return -1;
        }

        _devd.map_data = mmap(0, _devd.map_len, PROT_READ, MAP_SHARED, _devd.fd, 0); 
        if (MAP_FAILED == _devd.map_data) {
            dbg("map failed!\n");
            return -2;
        }
        return 0;
    }

};


FileIntf::FileIntf() {
    _pimpl = std::make_shared<FileIntfImpl>();
}
FileIntf::~FileIntf() {

}

FileIntf& FileIntf::get_instance() {
    static FileIntf file_intf;
    return file_intf;
}

RET_VAL FileIntf::init(const std::string conf_json) {
    return _pimpl->init(conf_json);
}
RET_VAL FileIntf::send_file(const std::string file_path) {
    return _pimpl->send_file(file_path);
}
RET_VAL FileIntf::send_path(const std::string path) {
    return _pimpl->send_path(path);
}
RET_VAL FileIntf::recv_file(const std::string file_path) {
    return _pimpl->recv_file(file_path);
}
RET_VAL FileIntf::recv_path(const std::string path, const std::string format) {
    return _pimpl->recv_path(path, format);
}

}//namespace bsd
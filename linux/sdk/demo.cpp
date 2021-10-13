
#include <vector>
#include <string>
#include <iostream>

#include "file_intf.hpp"

bool run();

int main(void) {
    run();
    return 0;
}

void cmd_split(const std::string cmd, std::vector<std::string>& cmds) {
    if (cmd.empty()) {
        return;
    }
    int32_t i = 0;
    int32_t j = 0;
    int32_t jk = 0;
    std::string oneword;
    while(cmd[i] != '\0') {
        if (' ' == cmd[i]) {
            if (0 != jk) {
                j++;
                cmds.push_back(oneword);
                oneword.clear();
            }
            jk = 0;
        }
        else {
            jk ++;
            oneword.append(1, cmd[i]);
        }
        i++;
    }
    if (jk) {
        cmds.push_back(oneword);
    }
}

void usage() {
    printf("use [cmd] <op1> <op2> ..., like below\n"
            "\th or ?: print this help\n"
            "\ts FILE: read from FILE and send to device.\n"
            "\tr FILE: receive and save to FILE.\n"
            "\tq: quit\n");
}

bool run() {
    bsd::FileIntf& fi = bsd::FileIntf::get_instance();
    if (bsd::RET_SUCCESS != fi.init()) {
        return false;
    }
    std::string cmd;
    std::vector<std::string> cmds;
    int ret = 0;
    usage();
    while(1) {
        cmd.clear();
        cmds.clear();
        std::getline(std::cin, cmd);
        cmd_split(cmd, cmds);
        if (cmds.empty()) {
            continue;
        }

        if ((cmds[0] == "s") && (cmds.size() > 1)) {
            fi.send_file(cmds[1]);
        }
        else if ((cmds[0] == "r") && (cmds.size() > 1)) {
            fi.recv_file(cmds[1]);
        }
        else if ((cmds[0] == "h") || (cmds[0] == "?")) {
            usage();
        }
        else if (cmds[0] == "q") {
            exit(0);
        }
        else {
            std::cout << "command error.\n";
            usage();
        }
        return true;
    }
}

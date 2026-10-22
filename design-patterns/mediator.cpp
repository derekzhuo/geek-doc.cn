// 中介者模式（Mediator）：同事只认识中介者，交互集中（O(N²) → O(N)）
// 演示：聊天室用户互不认识，消息经中介广播
#include <cstdio>
#include <string>
#include <vector>

class ChatMediator;
class ChatUser {                              // 同事
public:
    explicit ChatUser(ChatMediator& m, std::string name)
        : mediator_(m), name_(std::move(name)) {}
    void send(const std::string& msg);
    void recv(const std::string& from, const std::string& msg) const {
        std::printf("  [%s] 收到 %s 的消息: %s\n", name_.c_str(), from.c_str(), msg.c_str());
    }
    const std::string& name() const { return name_; }
private:
    ChatMediator& mediator_;
    std::string name_;
};

class ChatMediator {                          // 中介者：统一协调
public:
    void addUser(ChatUser* u) { users_.push_back(u); }
    void broadcast(ChatUser* from, const std::string& msg) {
        for (auto* u : users_)
            if (u != from) u->recv(from->name(), msg);
    }
private:
    std::vector<ChatUser*> users_;
};

void ChatUser::send(const std::string& msg) { mediator_.broadcast(this, msg); }

int main() {
    // 不使用模式：每个用户持有其他所有用户（N×(N-1) 条边），加人全改
    // 使用模式：用户互不认识，加人只 addUser
    ChatMediator chat;
    ChatUser alice(chat, "Alice");
    ChatUser bob(chat, "Bob");
    ChatUser carol(chat, "Carol");
    chat.addUser(&alice); chat.addUser(&bob); chat.addUser(&carol);

    std::puts("Alice 广播:");
    alice.send("hello everyone");
    return 0;
}

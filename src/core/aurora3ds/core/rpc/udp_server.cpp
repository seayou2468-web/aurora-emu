// Copyright 2019 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#include <atomic>
#include <cstring>
#include <functional>
#include <netinet/in.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <thread>
#include <unistd.h>
#include "common/common_types.h"
#include "common/logging/log.h"
#include "core/rpc/packet.h"
#include "core/rpc/udp_server.h"

namespace Core::RPC {

class UDPServer::Impl {
public:
    explicit Impl(std::function<void(std::unique_ptr<Packet>)> new_request_callback)
        : new_request_callback(std::move(new_request_callback)) {
        socket_fd = ::socket(AF_INET, SOCK_DGRAM, 0);
        if (socket_fd < 0) {
            LOG_ERROR(RPC_Server, "Failed to create UDP socket");
            return;
        }

        sockaddr_in bind_addr{};
        bind_addr.sin_family = AF_INET;
        bind_addr.sin_addr.s_addr = htonl(INADDR_ANY);
        bind_addr.sin_port = htons(45987);
        if (::bind(socket_fd, reinterpret_cast<sockaddr*>(&bind_addr), sizeof(bind_addr)) != 0) {
            LOG_ERROR(RPC_Server, "Failed to bind UDP socket");
            ::close(socket_fd);
            socket_fd = -1;
            return;
        }

        worker_thread = std::thread([this] { ReceiveLoop(); });
    }

    ~Impl() {
        should_run = false;
        if (socket_fd >= 0) {
            ::shutdown(socket_fd, SHUT_RDWR);
            ::close(socket_fd);
            socket_fd = -1;
        }
        if (worker_thread.joinable()) {
            worker_thread.join();
        }
    }

private:
    void ReceiveLoop() {
        while (should_run && socket_fd >= 0) {
            fd_set read_fds;
            FD_ZERO(&read_fds);
            FD_SET(socket_fd, &read_fds);
            timeval timeout{};
            timeout.tv_sec = 0;
            timeout.tv_usec = 200'000;
            const int ready = ::select(socket_fd + 1, &read_fds, nullptr, nullptr, &timeout);
            if (ready <= 0 || !FD_ISSET(socket_fd, &read_fds)) {
                continue;
            }

            socklen_t endpoint_size = sizeof(remote_endpoint);
            const ssize_t size =
                ::recvfrom(socket_fd, request_buffer.data(), request_buffer.size(), 0,
                           reinterpret_cast<sockaddr*>(&remote_endpoint), &endpoint_size);
            if (size < 0) {
                LOG_WARNING(RPC_Server, "Failed to receive data on UDP socket");
                continue;
            }
            HandleReceive(static_cast<std::size_t>(size));
        }
    }

    void HandleReceive(std::size_t size) {
        if (size >= MIN_PACKET_SIZE && size <= MAX_PACKET_SIZE) {
            PacketHeader header;
            std::memcpy(&header, request_buffer.data(), sizeof(header));
            if ((size - MIN_PACKET_SIZE) == header.packet_size) {
                u8* data = request_buffer.data() + MIN_PACKET_SIZE;
                std::function<void(Packet&)> send_reply_callback =
                    std::bind(&Impl::SendReply, this, remote_endpoint, std::placeholders::_1);
                std::unique_ptr<Packet> new_packet =
                    std::make_unique<Packet>(header, data, send_reply_callback);

                // Send the request to the upper layer for handling
                new_request_callback(std::move(new_packet));
            }
        } else {
            LOG_WARNING(RPC_Server, "Received message with wrong size: {}", size);
        }
    }

    void SendReply(sockaddr_in endpoint, Packet& reply_packet) {
        std::vector<u8> reply_buffer(MIN_PACKET_SIZE + reply_packet.GetPacketDataSize());
        auto reply_header = reply_packet.GetHeader();

        std::memcpy(reply_buffer.data(), &reply_header, sizeof(reply_header));
        std::memcpy(reply_buffer.data() + (4 * sizeof(u32)), reply_packet.GetPacketData().data(),
                    reply_packet.GetPacketDataSize());

        const ssize_t sent =
            ::sendto(socket_fd, reply_buffer.data(), reply_buffer.size(), 0,
                     reinterpret_cast<const sockaddr*>(&endpoint), sizeof(endpoint));

        if (sent < 0) {
            LOG_WARNING(RPC_Server, "Failed to send reply");
        } else {
            LOG_INFO(RPC_Server, "Sent reply version({}) id=({}) type=({}) size=({})",
                     reply_packet.GetVersion(), reply_packet.GetId(), reply_packet.GetPacketType(),
                     reply_packet.GetPacketDataSize());
        }
    }

    std::thread worker_thread;
    std::atomic<bool> should_run{true};
    int socket_fd{-1};
    std::array<u8, MAX_PACKET_SIZE> request_buffer;
    sockaddr_in remote_endpoint{};

    std::function<void(std::unique_ptr<Packet>)> new_request_callback;
};

UDPServer::UDPServer(std::function<void(std::unique_ptr<Packet>)> new_request_callback)
    : impl(std::make_unique<Impl>(new_request_callback)) {}

UDPServer::~UDPServer() = default;

} // namespace Core::RPC

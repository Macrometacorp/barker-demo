import QtQuick 2.12

Item {
    enum State {
        Init,
        HaveToken,
        ConnectToFeed,
        HaveFeed,
        ConnectToStream,
        Connected,
        Barking
    }
}

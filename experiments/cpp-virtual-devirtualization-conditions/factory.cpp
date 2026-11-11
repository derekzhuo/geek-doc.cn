#include "factory.hpp"

Base* makeOpen() {
    return new OpenDerived();
}

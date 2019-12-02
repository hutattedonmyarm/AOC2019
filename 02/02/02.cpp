#include <iostream>
#include <fstream>
#include <string>
#include <vector>

int main() {
    int desiredOutput{19690720};

    std::vector<int> program;
    std::vector<int> memory;

    std::ifstream file;
    file.open("input.txt");
    if (!file) {
        std::cout << "Error opening file";
        return 1;
    }

    std::string line;
    while (std::getline(file, line, ',')) {
        program.push_back(std::stoi(line));
    }
    file.close();

    size_t addr1{0};
    size_t addr2{0};
    size_t resultAdress{0};
    size_t operationSize{0};
    int result{0};

    for (size_t noun = 12; noun <= 99; noun++) {
        for (size_t verb = 2; verb <= 99; verb++) {
            memory = program;
            memory[1] = noun;
            memory[2] = verb;

            for (size_t pc = 0; memory[pc] != 99; pc += operationSize) {
                addr1 = memory[pc+1];
                addr2 = memory[pc+2];
                resultAdress = memory[pc+3];
                operationSize = 4;

                switch (memory[pc]) {
                case 1:
                    result = memory[addr1] + memory[addr2];
                    break;
                case 2:
                    result = memory[addr1] * memory[addr2];
                    break;
                default:
                    break;
                }

                memory[resultAdress] = result;
            }
            if (memory[0] == desiredOutput) {
                std::cout << noun * 100 + verb << '\n';
                break;
            }
        }
        if (memory[0] == desiredOutput) {
            break;
        }
    }
    std::cout << memory[0] << '\n';
    std::cout << "Done";
}
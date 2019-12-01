#include <iostream>
#include <fstream>
#include <cmath>
#include <sstream>
#include <string>

int getFuel(int mass) {
	int fuel {0};
	while (mass > 0) {
		mass = mass / 3 - 2;
		fuel += mass;
	}
	fuel -= mass;
	return fuel;
}

int main() {
	int mass{0};
	int totalFuelA{0};
	int totalFuelB{0};

	std::ifstream file;

	file.open("input.txt");

	if (!file) {
		std::cout << "Error opening file";
		return 1;
	}

	std::string line;
	while (std::getline(file, line)) {
		std::istringstream iss(line);
		if (!(iss >> mass)) {
			break;
		}
		totalFuelA += mass / 3 - 2;
		totalFuelB += getFuel(mass);
	}

	std::cout << "Part 1: " << totalFuelA << '\n' << "Part 2: " << totalFuelB << '\n';

}
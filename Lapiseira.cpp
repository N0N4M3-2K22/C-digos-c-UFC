#include <iostream>
#include <list>
#include <memory>
#include <sstream>
#include <utility>
#include <iomanip> //setprecision
#include <aux.hpp>

class Grafite{
    float calibre;
    std::string dureza;
    int tamanho;
public:
    Grafite(float calibre, std::string dureza, int tamanho) {
        this->calibre = calibre;
        this->dureza = dureza;
        this->tamanho = tamanho;
    }
    int desgastePorFolha() {
        if (dureza == "HB")
            return 1;
        if (dureza == "2B")
            return 2;
        if (dureza == "4B")
            return 4;
        return 6;
    }
    float getCalibre() {
        return calibre;
    }
    std::string getDureza() {
        return dureza;
    }
    int getTamanho() {
        return tamanho;
    }
    void setTamanho(int tamanho) {
        this->tamanho = tamanho;
    }
    std::string str() const {
        std::ostringstream os;
        os << std::fixed << std::setprecision(1) << calibre << ":" << dureza << ":" << tamanho;
        return os.str();
    }
};

std::ostream& operator<<(std::ostream& os, Grafite g) {
    return os << g.str();
}

using PGrafite = std::shared_ptr<Grafite>;

std::ostream& operator<<(std::ostream& os, PGrafite g) {
    return os << "[" << (g == nullptr ? "" : g->str()) << "]";
}

struct Lapiseira{
    float calibre {0.f};
    std::shared_ptr<Grafite> grafite {nullptr};
    std::list<std::shared_ptr<Grafite>> tambor;
    std::list<std::shared_ptr<Grafite>>::iterator it;

    Lapiseira(float calibre = 0.0) { //todo
        this->calibre = calibre;
    }

    bool inserir(std::shared_ptr<Grafite> grafite) {
        if(calibre != grafite->getCalibre()) {
    		std::cout << "fail: calibre incompativel" << "\n";
    		return false;
    	}
    	tambor.push_back(grafite);
        return true;

    }

    std::shared_ptr<Grafite> remover() {
        if(grafite != nullptr){
            auto aux = grafite;
            grafite = nullptr;
            return aux;
        }
        std::cout<< "fail: nao existe grafite no bico" << "\n";
        return grafite;
    }

    void write() {
        if(grafite != nullptr){
            if(grafite->getTamanho()<=10){
                std::cout << "fail: tamanho insuficiente" << "\n";
                return;
            }
            grafite->setTamanho(grafite->getTamanho() - grafite->desgastePorFolha());
            if(grafite!=nullptr && grafite->getTamanho()<10) {
    		    std::cout<< "fail: folha incompleta" << "\n";
    		    grafite->setTamanho(10);
    		    return;
    		}
        }else{
            std::cout << "fail: nao existe grafite no bico" << "\n";
            return;
        }
    }
    
    void puxar() {
        if(grafite == nullptr){
            if(tambor.size() == 0){
                std::cout << "fail: nao existe grafite no tambor" << "\n";
                return;
            }
            grafite = tambor.front();
            tambor.pop_front();
            return;
        }
        std::cout << "fail: ja existe grafite no bico" << "\n";
    }
    
    std::string str() const {
        if(tambor.size() == 0 && grafite == nullptr){
            std::ostringstream os;
            os << "calibre: " << calibre << ", bico: " << "[]," << " tambor: {}";
            return os.str(); // todo
        }else{
            std::ostringstream os;
            os << "calibre: " << calibre 
               << ", bico: " << grafite
               << ", tambor: {" << (tambor | aux::JOIN("")) << "}";
            return os.str();
        }
    }
};

std::ostream& operator<<(std::ostream& os, const Lapiseira& l) {
    return os << l.str();
}

int main() {
    aux::Chain chain;
    aux::Param param;
    Lapiseira lapiseira;

    auto FLOAT = [&param](int index) {return aux::to<float>(param[index]);};
    auto __INT = [&param](int index) {return aux::to<int>(param[index]);};

    chain["init"]   = [&]() { lapiseira = Lapiseira(FLOAT(1)); };
    chain["show"]   = [&]() { std::cout << lapiseira << std::endl; };
    chain["insert"] = [&]() { lapiseira.inserir(std::make_shared<Grafite>(FLOAT(1), param[2], __INT(3))); };
    chain["remove"] = [&]() { lapiseira.remover(); };
    chain["pull"]   = [&]() { lapiseira.puxar(); };
    chain["write"]  = [&]() { lapiseira.write(); };

    aux::execute(chain, param);
}
